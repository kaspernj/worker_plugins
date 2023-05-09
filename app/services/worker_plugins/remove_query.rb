class WorkerPlugins::RemoveQuery < WorkerPlugins::ApplicationService
  arguments :query, :workplace

  attr_reader :destroyed

  def perform
    remove_query_from_workplace
    succeed!(destroyed: destroyed, mode: :destroyed)
  end

  def remove_query_from_workplace
    links_query = workplace.workplace_links.where(resource_type: model_class.name, resource_id: query_with_selected_ids)
    @destroyed = links_query.pluck(:resource_id)
    links_query.delete_all
  end

  def model_class
    query.klass
  end

  def query_with_selected_ids
    WorkerPlugins::SelectColumnWithTypeCast.execute!(
      column_name_to_select: :id,
      column_to_compare_with: WorkerPlugins::WorkplaceLink.column_for_attribute(:resource_id),
      query: query.except(:order)
    )
  end
end
