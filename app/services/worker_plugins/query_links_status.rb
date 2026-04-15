class WorkerPlugins::QueryLinksStatus < WorkerPlugins::ApplicationService
  arguments :query, :workplace

  def perform
    checked_count = workplace
      .workplace_links
      .where(resource_type: query.klass.name, resource_id: query_with_selected_ids)
      .count

    query_count = query.count

    succeed!(
      all_checked: query_count == checked_count,
      checked_count:,
      query_count:,
      some_checked: checked_count.positive? && checked_count < query_count
    )
  end

  def query_with_selected_ids
    WorkerPlugins::SelectColumnWithTypeCast.execute!(
      column_name_to_select: query.klass.primary_key,
      column_to_compare_with: WorkerPlugins::WorkplaceLink.column_for_attribute(:resource_id),
      query: query.distinct
    )
  end
end
