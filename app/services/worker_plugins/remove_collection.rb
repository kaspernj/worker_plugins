class WorkerPlugins::RemoveCollection < WorkerPlugins::ApplicationService
  attr_reader :destroyed, :query, :workplace

  def initialize(query:, workplace:)
    @query = query
    @workplace = workplace
    @destroyed = {}
  end

  def execute
    remove_query_from_workplace
    succeed!(destroyed: destroyed, mode: :destroyed)
  end

  def add_query_to_workplace
    created[model_class.name] ||= []
    primary_key = resources_to_add.klass.primary_key
    created[model_class.name] += resources_to_add.pluck(primary_key.to_sym)

    select_sql = resources_to_add.select("
      NOW(),
      '#{resources_to_add.klass.name}',
      \"#{resources_to_add.klass.table_name}\".\"#{primary_key}\",
      NOW(),
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

  def remove_query_from_workplace
    links_query = workplace.workplace_links.where(resource_type: model_class.name, resource_id: query.select(:id))

    destroyed[model_class.name] ||= []
    destroyed[model_class.name] += links_query.pluck(:resource_id)

    links_query.delete_all
  end

  def model_class
    query.klass
  end
end
