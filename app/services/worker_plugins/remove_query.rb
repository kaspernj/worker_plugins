class WorkerPlugins::RemoveQuery < WorkerPlugins::ApplicationService
  arguments :query, :workplace

  def perform
    succeed!(affected_count: links_scope.delete_all)
  end

  def links_scope
    scope = workplace.workplace_links.where(resource_type: model_class.name)
    return scope if unscoped_query?

    scope.where(resource_id: query_with_selected_ids)
  end

  # If the caller's query has no meaningful scoping applied, the `resource_id
  # IN (SELECT ... FROM <target_table>)` subquery would simply materialize
  # every row of the target model — for 340k+ users that's a full-table scan
  # with no semantic effect other than preserving orphaned links. The
  # `resource_type = ?` filter alone is enough to pin the DELETE to this
  # workplace's links of the given type, so we short-circuit the subquery in
  # that case. Orphaned links (whose resource row has since been deleted) are
  # deleted alongside live ones, which matches caller intent ("remove
  # everything matching the query") and is the correct thing to do with
  # dead references anyway.
  def unscoped_query?
    relation = query
    relation.where_clause.empty? &&
      relation.joins_values.empty? &&
      relation.left_outer_joins_values.empty? &&
      relation.group_values.empty? &&
      relation.having_clause.empty? &&
      relation.limit_value.nil? &&
      relation.offset_value.nil? &&
      relation.from_clause.value.nil? &&
      relation.with_values.empty?
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
