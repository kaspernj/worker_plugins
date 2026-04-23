class WorkerPlugins::AddQuery < WorkerPlugins::ApplicationService
  attr_reader :query, :workplace

  def initialize(query:, workplace:)
    @query = query
      .except(:order) # This fixes crashes in Postgres
    @workplace = workplace
  end

  def perform
    created # Capture already_linked_ids and candidate_ids before the INSERT
    add_query_to_workplace
    succeed!(created:)
  end

  def add_query_to_workplace
    WorkerPlugins::WorkplaceLink.connection.execute(sql)
  end

  # The previous implementation ran the same expensive `NOT EXISTS` anti-join
  # twice — once via `pluck` to build `created`, and again inside the
  # `INSERT ... SELECT`. On workplaces with hundreds of thousands of candidate
  # rows that doubled the wall time. We now compute `created` by diffing a
  # cheap index-only scan of the candidate primary keys against a cheap
  # index-only scan of this workplace's existing links, and let the INSERT
  # itself dedupe through the `unique_resource_on_workspace` index.
  def created
    @created ||= begin
      linked = already_linked_ids_as_strings
      candidate_ids.reject { |id| linked.include?(id.to_s) }
    end
  end

  def candidate_ids
    @candidate_ids ||= resources_to_add.pluck(primary_key.to_sym)
  end

  def already_linked_ids_as_strings
    @already_linked_ids_as_strings ||= ids_added_already_query.pluck(:resource_id).to_set
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
    # skip the `WHERE NOT EXISTS` anti-join entirely — duplicates are rejected
    # on INSERT by the dialect-specific conflict clause in #sql. `.distinct`
    # still handles same-row duplicates produced by joins in the caller's
    # query (e.g. `User.joins(:tasks)`).
    @resources_to_add ||= query.distinct
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
