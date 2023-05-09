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
    succeed!(created: created)
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
      .where(resource_type: model_class.name, resource_id: query_with_selected_ids)
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

  def query_with_selected_ids
    WorkerPlugins::SelectColumnWithTypeCast.execute!(
      column_name_to_select: :id,
      column_to_compare_with: WorkerPlugins::WorkplaceLink.column_for_attribute(:resource_id),
      query: query
    )
  end

  def resources_to_add
    @resources_to_add ||= query
      .distinct
      .where
      .not(id: ids_added_already)
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
