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

    # When the query applies no scoping, the original `resource_id IN (SELECT
    # DISTINCT <target_table>.id FROM <target_table>)` subquery materialized
    # every row of the target model just to count — 2+ seconds on a 340k-row
    # target. We drop the DISTINCT subquery and instead `INNER JOIN` the
    # target table on its primary key so the composite index on links drives
    # the scan and each matching link does a cheap PK probe to confirm the
    # target row still exists. Orphaned links (whose target has since been
    # deleted) are correctly excluded from the count, so `checked_count`
    # never exceeds `query_count`.
    return base_scope.joins(unscoped_target_join_sql).count if relation_unscoped?(query)

    base_scope.where(resource_id: query_with_selected_ids).count
  end

  def unscoped_target_join_sql
    target_table = quote_table(query.klass.table_name)
    target_pk = "#{target_table}.#{quote_column(query.klass.primary_key)}"
    resource_id_column = "#{quote_table(WorkerPlugins::WorkplaceLink.table_name)}.#{quote_column(:resource_id)}"

    "INNER JOIN #{target_table} ON #{target_pk} = #{resource_id_expression_for_join(resource_id_column)}"
  end

  # On MySQL / MariaDB and SQLite, implicit conversion handles comparing the
  # target's primary key against the VARCHAR `resource_id` column. Postgres
  # is strict about types and needs an explicit cast when they differ.
  def resource_id_expression_for_join(resource_id_column)
    return resource_id_column unless postgres?

    target_pk_type = query.klass.column_for_attribute(query.klass.primary_key).type
    resource_id_type = WorkerPlugins::WorkplaceLink.column_for_attribute(:resource_id).type

    return resource_id_column if target_pk_type == resource_id_type

    case target_pk_type
    when :uuid then "CAST(#{resource_id_column} AS UUID)"
    when :integer then "CAST(#{resource_id_column} AS BIGINT)"
    else resource_id_column
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
