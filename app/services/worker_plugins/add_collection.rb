class WorkerPlugins::AddCollection < WorkerPlugins::ApplicationService
  attr_reader :query, :workplace

  def initialize(query:, workplace:)
    @query = query
    @workplace = workplace
  end

  def execute
    created # Cache which are about to be created
    add_query_to_workplace
    succeed!(created: created)
  end

  def add_query_to_workplace
    WorkerPlugins::WorkplaceLink.connection.execute(sql)
  end

  def created
    @created ||= resources_to_add.pluck(primary_key.to_sym)
  end

  def ids_added_already
    @ids_added_already ||= workplace
      .workplace_links
      .where(resource_type: model_class.name, resource_id: query.select(:id))
      .select(:resource_id)
  end

  def model_class
    @model_class ||= query.klass
  end

  def primary_key
    @primary_key ||= resources_to_add.klass.primary_key
  end

  def resources_to_add
    @resources_to_add ||= query.where.not(id: ids_added_already)
  end

  def select_sql
    @select_sql ||= resources_to_add
      .select("
        #{db_now_method},
        '#{resources_to_add.klass.name}',
        \"#{resources_to_add.klass.table_name}\".\"#{primary_key}\",
        #{db_now_method},
        '#{workplace.id}'
      ")
      .to_sql
  end

  def sql
    @sql ||= begin
      "
        INSERT INTO
          worker_plugins_workplace_links

        (
          created_at,
          resource_type,
          resource_id,
          updated_at,
          workplace_id
        )

        #{select_sql}
      "
    end
  end
end
