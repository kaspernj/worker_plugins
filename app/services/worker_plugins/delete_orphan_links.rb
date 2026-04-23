class WorkerPlugins::DeleteOrphanLinks < WorkerPlugins::ApplicationService
  # Deletes `worker_plugins_workplace_links` whose target row no longer
  # exists — i.e. links pointing at a resource that was destroyed without
  # the link being cleaned up alongside. Intended to be scheduled by the
  # consumer application from a background job.
  #
  # Links whose `resource_type` doesn't resolve to a Ruby class (e.g. a
  # model was renamed or removed) are left alone — cleaning those up is
  # a separate concern that requires human judgement.
  def perform
    deleted_count = distinct_resource_types.sum do |resource_type|
      delete_orphans_for(resource_type)
    end

    succeed!(deleted_count:)
  end

  def distinct_resource_types
    WorkerPlugins::WorkplaceLink.distinct.pluck(:resource_type)
  end

  def delete_orphans_for(resource_type)
    model_class = resource_type.safe_constantize
    return 0 unless model_class

    WorkerPlugins::WorkplaceLink
      .where(resource_type:)
      .where.not(resource_id: live_ids_query(model_class))
      .delete_all
  end

  def live_ids_query(model_class)
    WorkerPlugins::SelectColumnWithTypeCast.execute!(
      column_name_to_select: model_class.primary_key,
      column_to_compare_with: WorkerPlugins::WorkplaceLink.column_for_attribute(:resource_id),
      query: model_class.all
    )
  end
end
