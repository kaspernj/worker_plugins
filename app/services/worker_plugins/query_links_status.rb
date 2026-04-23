class WorkerPlugins::QueryLinksStatus < WorkerPlugins::ApplicationService
  arguments :query, :workplace

  def perform
    query_count = query.count
    checked_count = count_linked_rows

    succeed!(
      all_checked: query_count == checked_count,
      checked_count:,
      query_count:,
      some_checked: checked_count.positive? && checked_count < query_count
    )
  end

  def count_linked_rows
    base_scope = workplace.workplace_links.where(resource_type: query.klass.name)

    # When the query applies no scoping, the `resource_id IN (SELECT DISTINCT
    # <target_table>.id FROM <target_table>)` subquery would materialize every
    # row of the target model just to count — on a 340k-user workplace that's
    # a 2+ second full-table scan. The `resource_type = ?` filter alone is
    # enough in that case, and it rides the `(workplace_id, resource_type,
    # resource_id)` composite index for an index-only count.
    return base_scope.count if relation_unscoped?(query)

    base_scope.where(resource_id: query_with_selected_ids).count
  end

  def query_with_selected_ids
    WorkerPlugins::SelectColumnWithTypeCast.execute!(
      column_name_to_select: query.klass.primary_key,
      column_to_compare_with: WorkerPlugins::WorkplaceLink.column_for_attribute(:resource_id),
      query: query.distinct
    )
  end
end
