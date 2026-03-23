class WorkerPlugins::SelectColumnWithTypeCast < WorkerPlugins::ApplicationService
  arguments :column_name_to_select, :column_to_compare_with, :query

  def perform
    return succeed! query.select(column_name_to_select) if same_type?

    if column_to_compare_with.type == :integer
      succeed! query_with_integer
    elsif column_to_compare_with.type == :uuid
      succeed! query_with_uuid
    else
      succeed! query_with_varchar
    end
  end

  def column_to_select
    @column_to_select ||= model_class.column_for_attribute(column_name_to_select)
  end

  def model_class
    @model_class ||= query.klass
  end

  def query_with_integer
    query.select("CAST(#{model_class.table_name}.#{column_name_to_select} AS BIGINT)")
  end

  def query_with_varchar
    query.select("CAST(#{model_class.table_name}.#{column_name_to_select} AS VARCHAR)")
  end

  def query_with_uuid
    query.select("CAST(#{model_class.table_name}.#{column_name_to_select} AS UUID)")
  end

  def same_type?
    column_to_select.type == column_to_compare_with.type
  end
end
