class WorkerPlugins::AddCollection < WorkerPlugins::ApplicationService
  attr_reader :created, :query, :workplace

  def initialize(query:, workplace:)
    @query = query
    @workplace = workplace
    @created = {}
  end

  def execute
    add_query_to_workplace
    succeed!(created: created, mode: :created)
  end

  def add_query_to_workplace
    created[model_class.name] ||= []
    primary_key = resources_to_add.klass.primary_key
    created[model_class.name] += resources_to_add.pluck(primary_key.to_sym)

    select_sql = resources_to_add.select("
      #{db_now_method},
      '#{resources_to_add.klass.name}',
      \"#{resources_to_add.klass.table_name}\".\"#{primary_key}\",
      #{db_now_method},
      '#{workplace.id}'
    ")

    sql = "
      INSERT INTO
        worker_plugins_workplace_links

      (
        created_at,
        resource_type,
        resource_id,
        updated_at,
        workplace_id
      )

      #{select_sql.to_sql}
    "

    WorkerPlugins::WorkplaceLink.connection.execute(sql)
  end

  def ids_added_already
    workplace
      .workplace_links
      .where(resource_type: model_class.name, resource_id: query.select(:id))
      .select(:resource_id)
  end

  def model_class
    query.klass
  end

  def resources_to_add
    query.where.not(id: ids_added_already)
  end
end
