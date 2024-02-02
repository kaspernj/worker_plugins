class WorkerPlugins::QueryLinksStatus < WorkerPlugins::ApplicationService
  arguments :query, :workplace

  def perform
    checked_count = workplace
      .workplace_links
      .where(resource_id: query.distinct.select(query.klass.primary_key))
      .count

    query_count = query.count

    succeed!(
      all_checked: query_count == checked_count,
      checked_count:,
      query_count:,
      some_checked: checked_count.positive? && checked_count < query_count
    )
  end
end
