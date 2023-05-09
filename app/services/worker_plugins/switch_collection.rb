class WorkerPlugins::SwitchCollection < WorkerPlugins::ApplicationService
  arguments :query, :workplace

  def perform
    if resources_to_add.count.zero?
      result = WorkerPlugins::RemoveQuery.execute!(query: query, workplace: workplace)
      succeed!(
        destroyed: result.fetch(:destroyed),
        mode: :destroyed
      )
    else
      result = WorkerPlugins::AddQuery.execute!(query: query, workplace: workplace)
      succeed!(
        created: result.fetch(:created),
        mode: :created
      )
    end
  end

  def ids_added_already_query
    workplace
      .workplace_links
      .where(resource_type: model_class.name, resource_id: query_with_selected_ids)
  end

  def ids_added_already
    WorkerPlugins::SelectColumnWithTypeCast.execute!(
      column_name_to_select: :resource_id,
      column_to_compare_with: model_class.column_for_attribute(:id),
      query: ids_added_already_query
    )
  end

  def model_class
    @model_class ||= query.klass
  end

  def query_with_selected_ids
    WorkerPlugins::SelectColumnWithTypeCast.execute!(
      column_name_to_select: :id,
      column_to_compare_with: WorkerPlugins::WorkplaceLink.column_for_attribute(:resource_id),
      query: query
    )
  end

  def resources_to_add
    @resources_to_add ||= query.where.not(id: ids_added_already)
  end
end
