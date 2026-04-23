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
    return true if column_to_select.type == column_to_compare_with.type

    mysql_implicit_conversion_safe?
  end

  # On MySQL / MariaDB, implicit conversion handles comparisons between any
  # string-ish column types (VARCHAR, CHAR, BINARY, UUID, or types AR doesn't
  # recognize — e.g. MariaDB's native UUID type when using an older mysql2
  # adapter). The explicit CAST is only needed when one side is numeric,
  # because MySQL would then force a string → number conversion that loses
  # rows containing non-numeric values.
  def mysql_implicit_conversion_safe?
    return false unless mysql?

    !numeric_type?(column_to_select.type) && !numeric_type?(column_to_compare_with.type)
  end

  def numeric_type?(type)
    %i[integer decimal float bigint].include?(type)
  end
end
