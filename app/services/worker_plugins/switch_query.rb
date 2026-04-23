class WorkerPlugins::SwitchQuery < WorkerPlugins::ApplicationService
  arguments :query, :workplace

  def perform
    add_result = WorkerPlugins::AddQuery.execute!(query:, workplace:)
    add_count = add_result.fetch(:affected_count)

    if add_count.positive?
      succeed!(affected_count: add_count, mode: :created)
    else
      remove_result = WorkerPlugins::RemoveQuery.execute!(query:, workplace:)
      succeed!(affected_count: remove_result.fetch(:affected_count), mode: :destroyed)
    end
  end
end
