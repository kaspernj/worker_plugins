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
    if mysql?
      query.select("CAST(#{model_class.table_name}.#{column_name_to_select} AS SIGNED)")
    else
      query.select("CAST(#{model_class.table_name}.#{column_name_to_select} AS BIGINT)")
    end
  end

  def query_with_varchar
    if mysql?
      query.select("CAST(#{model_class.table_name}.#{column_name_to_select} AS CHAR)")
    else
      query.select("CAST(#{model_class.table_name}.#{column_name_to_select} AS VARCHAR)")
    end
  end

  def query_with_uuid
    if postgres?
      query.select("CAST(#{model_class.table_name}.#{column_name_to_select} AS UUID)")
    else
      query_with_varchar
    end
  end

  def same_type?
    column_to_select.type == column_to_compare_with.type || mysql_string_uuid_compatible_types?
  end

  def mysql_string_uuid_compatible_types?
    return false unless mysql?

    types = [column_to_select.type, column_to_compare_with.type]

    types.include?(:string) && types.include?(:uuid)
  end
end
