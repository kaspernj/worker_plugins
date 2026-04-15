class WorkerPlugins::SwitchQuery < WorkerPlugins::ApplicationService
  arguments :query, :workplace

  def perform
    add_query_service = WorkerPlugins::AddQuery.new(query:, workplace:)
    created = add_query_service.created

    if created.empty?
      result = WorkerPlugins::RemoveQuery.execute!(query:, workplace:)
      succeed!(
        destroyed: result.fetch(:destroyed),
        mode: :destroyed
      )
    else
      succeed!(
        created: add_query_service.tap(&:add_query_to_workplace).created,
        mode: :created
      )
    end
  end
end
