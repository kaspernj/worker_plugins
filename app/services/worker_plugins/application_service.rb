class WorkerPlugins::ApplicationService < ServicePattern::Service
  def db_now_value
    @db_now_value ||= begin
      time_string = Time.zone.now.strftime("%Y-%m-%d %H:%M:%S")

      if postgres?
        "CAST(#{quote(time_string)} AS TIMESTAMP)"
      else
        quote(time_string)
      end
    end
  end

  def quote(value)
    WorkerPlugins::Workplace.connection.quote(value)
  end

  def quote_column(value)
    WorkerPlugins::Workplace.connection.quote_column_name(value)
  end

  def quote_table(value)
    WorkerPlugins::Workplace.connection.quote_table_name(value)
  end

  def postgres?
    ActiveRecord::Base.connection.instance_values["config"][:adapter].downcase.include?("postgres")
  end

  def sqlite?
    ActiveRecord::Base.connection.instance_values["config"][:adapter].downcase.include?("sqlite")
  end

  def mysql?
    adapter_name = ActiveRecord::Base.connection.instance_values["config"][:adapter].downcase

    adapter_name.include?("mysql") || adapter_name.include?("trilogy")
  end

  # True when a relation applies no row-narrowing scope — so filtering
  # workplace links with `resource_id IN (SELECT ... FROM <target_table>)` adds
  # no semantic value and just forces the database to materialize every row
  # of the target model. Call sites (RemoveQuery, QueryLinksStatus) use this
  # to drop the subquery and count/delete by `resource_type` alone on large
  # target models (e.g. 340k+ users).
  def relation_unscoped?(relation)
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
end
