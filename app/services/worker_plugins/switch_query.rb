class WorkerPlugins::SwitchQuery < WorkerPlugins::ApplicationService
  arguments :query, :workplace

  def perform
    # Decide mode *before* running the insert. Deciding it from AddQuery's
    # post-insert `affected_count` would make concurrent "add" toggles
    # destructive: if request A's INSERT commits first, overlapping
    # request B would see `affected_count == 0` from its own (no-op)
    # INSERT and flip to RemoveQuery, wiping out what A just added. A
    # pre-insert EXISTS probe keeps the race window small in the same
    # way the previous candidate-pluck approach did, without materializing
    # any ids into Ruby.
    if any_unlinked_candidate?
      add_result = WorkerPlugins::AddQuery.execute!(query:, workplace:)
      succeed!(affected_count: add_result.fetch(:affected_count), mode: :created)
    else
      remove_result = WorkerPlugins::RemoveQuery.execute!(query:, workplace:)
      succeed!(affected_count: remove_result.fetch(:affected_count), mode: :destroyed)
    end
  end

  def any_unlinked_candidate?
    add_service = WorkerPlugins::AddQuery.new(query:, workplace:)

    add_service
      .query
      .distinct
      .where("NOT EXISTS (#{add_service.existing_workplace_link_exists_sql})")
      .exists?
  end
end
