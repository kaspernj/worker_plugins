class WorkerPlugins::SelectColumnWithTypeCast < WorkerPlugins::ApplicationService
  attr_reader :column_name_to_select, :column_to_compare_with, :query

  def initialize(column_name_to_select:, column_to_compare_with:, query:)
    @column_name_to_select = column_name_to_select
    @column_to_compare_with = column_to_compare_with
    @query = query
  end

  def execute
    return succeed! query.select(column_name_to_select) if column_to_select.type == column_to_compare_with.type

    if column_to_compare_with.type == :string
      succeed! query.select("CAST(#{model_class.table_name}.#{column_name_to_select} AS VARCHAR)")
    elsif column_to_compare_with.type == :integer
      succeed! query.select("CAST(#{model_class.table_name}.#{column_name_to_select} AS BIGINT)")
    else
      raise "Unknown type: #{column_to_compare_with.type}"
    end
  end

  def column_to_select
    @column_to_select ||= model_class.column_for_attribute(column_name_to_select)
  end

  def model_class
    @model_class ||= query.klass
  end
end
