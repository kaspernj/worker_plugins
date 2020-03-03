class WorkerPlugins::RemoveCollection < WorkerPlugins::ApplicationService
  attr_reader :destroyed, :query, :workplace

  def initialize(query:, workplace:)
    @query = query
    @workplace = workplace
  end

  def execute
    remove_query_from_workplace
    succeed!(destroyed: destroyed, mode: :destroyed)
  end

  def remove_query_from_workplace
    links_query = workplace.workplace_links.where(resource_type: model_class.name, resource_id: query.select(:id))
    @destroyed = links_query.pluck(:resource_id)
    links_query.delete_all
  end

  def model_class
    query.klass
  end
end
