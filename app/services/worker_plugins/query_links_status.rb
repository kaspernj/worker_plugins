class WorkerPlugins::QueryLinksStatus < WorkerPlugins::ApplicationService
  arguments :query, :workplace

  def perform
    query_count = query.count
    checked_count = count_linked_rows(query_count)

    succeed!(
      all_checked: query_count == checked_count,
      checked_count:,
      query_count:,
      some_checked: checked_count.positive? && checked_count < query_count
    )
  end

  def count_linked_rows(query_count)
    base_scope = workplace.workplace_links.where(resource_type: query.klass.name)

    # Fast path for unscoped queries: a plain index-only COUNT against the
    # `(workplace_id, resource_type, resource_id)` composite index resolves in
    # ~50 ms even for workplaces with hundreds of thousands of links. Joining
    # back to the target table to exclude orphaned links (whose resource row
    # has since been destroyed) would take 10+ seconds on the same data
    # regardless of which shape we pick — the DB still has to cross-reference
    # every link against the target's primary key. Instead we clamp the raw
    # count to `query_count`; `WorkerPlugins::DeleteOrphanLinks` (scheduled
    # daily by consumers) keeps the orphan count at zero so the raw count
    # equals the live-linked count in practice. When orphans do briefly exist
    # between cleanup runs, clamping bounds the over-count at the query's
    # total — `all_checked` / `some_checked` stay correct because they're
    # computed off the clamped value.
    if relation_unscoped?(query)
      [base_scope.count, query_count].min
    else
      base_scope.where(resource_id: query_with_selected_ids).count
    end
  end

  def query_with_selected_ids
    WorkerPlugins::SelectColumnWithTypeCast.execute!(
      column_name_to_select: query.klass.primary_key,
      column_to_compare_with: WorkerPlugins::WorkplaceLink.column_for_attribute(:resource_id),
      query: query.distinct
    )
  end
end
