class WorkerPlugins::AddQuery < WorkerPlugins::ApplicationService
  attr_reader :query, :workplace

  def initialize(query:, workplace:)
    @query = query
      .except(:order) # This fixes crashes in Postgres
    @workplace = workplace
  end

  def perform
    created # Cache which are about to be created
    add_query_to_workplace
    succeed!(created:)
  end

  def add_query_to_workplace
    WorkerPlugins::WorkplaceLink.connection.execute(sql)
  end

  def created
    @created ||= resources_to_add.pluck(primary_key.to_sym)
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
    @primary_key ||= resources_to_add.klass.primary_key
  end

  def resources_to_add
    # Correlate per row with NOT EXISTS instead of NOT IN + a materialized
    # subquery. The old form expanded into a nested `resource_id IN (SELECT
    # CAST(users.id AS CHAR) FROM users)` that did a full scan of the target
    # table when the outer query was unfiltered — 60s+ on 340k+ users. This
    # uses the `(workplace_id, resource_type, resource_id)` composite index
    # for an index seek per row.
    @resources_to_add ||= query
      .distinct
      .where("NOT EXISTS (#{existing_workplace_link_exists_sql})")
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
    return primary_key_column if model_class.column_for_attribute(model_class.primary_key).type ==
                                 WorkerPlugins::WorkplaceLink.column_for_attribute(:resource_id).type

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
      INSERT INTO
        worker_plugins_workplace_links

      (
        created_at,
        resource_type,
        resource_id,
        updated_at,
        workplace_id
      )

      #{select_sql}
    "
  end
end
