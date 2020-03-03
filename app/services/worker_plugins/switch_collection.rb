class WorkerPlugins::SwitchCollection < WorkerPlugins::ApplicationService
  attr_reader :query, :workplace

  def initialize(query:, workplace:)
    @query = query
    @workplace = workplace
  end

  def execute
    if resources_to_add.count.zero?
      result = WorkerPlugins::RemoveCollection.execute!(query: query, workplace: workplace)
      succeed!(
        destroyed: result.fetch(:destroyed),
        mode: :destroyed
      )
    else
      result = WorkerPlugins::AddCollection.execute!(query: query, workplace: workplace)
      succeed!(
        created: result.fetch(:created),
        mode: :created
      )
    end
  end

  def ids_added_already
    workplace
      .workplace_links
      .where(resource_type: model_class.name, resource_id: query.select(:id))
      .select(:resource_id)
  end

  def model_class
    @model_class ||= query.klass
  end

  def resources_to_add
    @resources_to_add ||= query.where.not(id: ids_added_already)
  end
end
