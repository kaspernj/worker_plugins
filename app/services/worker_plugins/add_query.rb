class WorkerPlugins::AddQuery < WorkerPlugins::ApplicationService
  attr_reader :query, :workplace

  def initialize(query:, workplace:)
    @query = query
      .except(:order) # This fixes crashes in Postgres
    @workplace = workplace
  end

  def perform
    succeed!(affected_count: add_query_to_workplace)
  end

  def add_query_to_workplace
    WorkerPlugins::WorkplaceLink.connection.exec_update(sql, "WorkerPlugins::AddQuery INSERT", [])
  end

  def ids_added_already_query
    workplace
      .workplace_links
      .where(resource_type: model_class.name)
  end

  def ids_added_already
    WorkerPlugins::SelectColumnWithTypeCast.execute!(
      column_name_to_select: :resource_id,
      column_to_compare_with: model_class.column_for_attribute(:id),
      query: ids_added_already_query
    )
  end

  def model_class
    @model_class ||= query.klass
  end

  def primary_key
    @primary_key ||= model_class.primary_key
  end

  def resources_to_add
    # The unique index on `(workplace_id, resource_type, resource_id)` lets us
    # skip the `WHERE NOT EXISTS` anti-join for the common unbounded query —
    # duplicates are rejected on INSERT by the dialect-specific conflict
    # clause in #sql. `.distinct` still handles same-row duplicates produced
    # by joins in the caller's query (e.g. `User.joins(:tasks)`).
    #
    # When the caller scopes with `.limit` / `.offset`, we keep the anti-join
    # so already-linked rows are filtered *before* the window is applied;
    # otherwise `Task.limit(100)` could insert fewer than 100 new rows when
    # some of those 100 are already linked.
    @resources_to_add ||= if query.limit_value || query.offset_value
      query.distinct.where("NOT EXISTS (#{existing_workplace_link_exists_sql})")
    else
      query.distinct
    end
  end

  def existing_workplace_link_exists_sql
    resource_id_column = "#{quote_table(WorkerPlugins::WorkplaceLink.table_name)}.#{quote_column(:resource_id)}"

    workplace
      .workplace_links
      .where(resource_type: model_class.name)
      .where("#{resource_id_column} = #{model_primary_key_cast_for_resource_id}")
      .select(1)
      .to_sql
  end

  def model_primary_key_cast_for_resource_id
    primary_key_column = "#{quote_table(model_class.table_name)}.#{quote_column(model_class.primary_key)}"

    # MySQL and SQLite do implicit conversion when comparing integer/uuid/string
    # primary keys to the `resource_id` VARCHAR column. Postgres is strict about
    # types and needs an explicit cast.
    return primary_key_column unless postgres?

    primary_key_type = model_class.column_for_attribute(model_class.primary_key).type
    resource_id_type = WorkerPlugins::WorkplaceLink.column_for_attribute(:resource_id).type

    return primary_key_column if primary_key_type == resource_id_type

    "CAST(#{primary_key_column} AS VARCHAR)"
  end

  def select_sql
    @select_sql ||= resources_to_add
      .select("
        #{db_now_value},
        #{quote(resources_to_add.klass.name)},
        #{quote_table(resources_to_add.klass.table_name)}.#{quote_column(primary_key)},
        #{db_now_value},
        #{select_workplace_id_sql}
      ")
      .to_sql
  end

  def select_workplace_id_sql
    workplace_id_column = WorkerPlugins::WorkplaceLink.columns.find { |column| column.name == "workplace_id" }

    if workplace_id_column.type == :uuid
      "CAST(#{quote(workplace.id)} AS UUID)"
    else
      quote(workplace.id)
    end
  end

  def sql
    @sql ||= "
      #{insert_clause} INTO
        worker_plugins_workplace_links

      (
        created_at,
        resource_type,
        resource_id,
        updated_at,
        workplace_id
      )

      #{select_sql}
      #{conflict_clause}
    "
  end

  def insert_clause
    if mysql?
      "INSERT IGNORE"
    elsif sqlite?
      "INSERT OR IGNORE"
    else
      "INSERT"
    end
  end

  def conflict_clause
    return "" unless postgres?

    "ON CONFLICT (workplace_id, resource_type, resource_id) DO NOTHING"
  end
end
