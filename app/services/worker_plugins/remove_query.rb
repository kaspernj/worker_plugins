class WorkerPlugins::RemoveQuery < WorkerPlugins::ApplicationService
  arguments :query, :workplace

  def perform
    succeed!(affected_count: links_scope.delete_all)
  end

  def links_scope
    scope = workplace.workplace_links.where(resource_type: model_class.name)
    # When the caller's query applies no scoping, the `resource_id IN (SELECT
    # ... FROM <target_table>)` subquery would materialize every row of the
    # target model — the `resource_type = ?` filter alone is enough. Orphaned
    # links (whose resource row has since been deleted) are deleted alongside
    # live ones, which matches caller intent ("remove everything matching")
    # and is the correct thing to do with dead references anyway.
    return scope if relation_unscoped?(@query)

    scope.where(resource_id: query_with_selected_ids)
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
