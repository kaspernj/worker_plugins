class WorkerPlugins::DeleteOldWorkplaces < WorkerPlugins::ApplicationService
  arguments :older_than
  argument :batch_size, default: 1_000

  # Deletes workplaces that haven't seen any activity since `older_than.ago` —
  # both the workplace record itself is older than the cutoff *and* none of
  # its links have been created / updated since. Links on deleted workplaces
  # are removed with the parent via `dependent: :destroy`, but this service
  # uses raw `delete_all` in batches to skip per-row callbacks and keep
  # long-running cleanup jobs cheap.
  #
  # Intended to be scheduled by the consumer application from a Sidekiq
  # worker (or equivalent) — the gem does not register a scheduler of its
  # own.
  def perform
    cutoff = older_than.ago
    workplaces_deleted = 0
    links_deleted = 0

    stale_workplaces(cutoff).in_batches(of: batch_size) do |batch|
      batch_ids = batch.pluck(:id)

      links_deleted += WorkerPlugins::WorkplaceLink
        .where(workplace_id: batch_ids)
        .delete_all
      workplaces_deleted += WorkerPlugins::Workplace
        .where(id: batch_ids)
        .delete_all
    end

    succeed!(workplaces_deleted:, links_deleted:)
  end

  def stale_workplaces(cutoff)
    workplaces_table = quote_table(WorkerPlugins::Workplace.table_name)
    links_table = quote_table(WorkerPlugins::WorkplaceLink.table_name)

    WorkerPlugins::Workplace
      .where("#{workplaces_table}.#{quote_column(:updated_at)} < ?", cutoff)
      .where(<<~SQL.squish, cutoff)
        NOT EXISTS (
          SELECT 1 FROM #{links_table}
          WHERE #{links_table}.#{quote_column(:workplace_id)} = #{workplaces_table}.#{quote_column(:id)}
            AND #{links_table}.#{quote_column(:updated_at)} >= ?
        )
      SQL
  end
end
