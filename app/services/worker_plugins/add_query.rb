class WorkerPlugins::AddQuery < WorkerPlugins::ApplicationService
  attr_reader :query, :workplace

  def initialize(query:, workplace:)
    @query = query
      .except(:order) # This fixes crashes in Postgres
    @workplace = workplace
  end

  def perform
    created # Cache which are about to be created
    add_query_to_workplace
    succeed!(created:)
  end

  def add_query_to_workplace
    timestamp = Time.zone.now

    created.each_slice(500) do |resource_ids|
      WorkerPlugins::WorkplaceLink.insert_all!( # rubocop:disable Rails/SkipsModelValidations
        resource_ids.map do |resource_id|
          {
            created_at: timestamp,
            resource_id:,
            resource_type: model_class.name,
            updated_at: timestamp,
            workplace_id: workplace.id
          }
        end
      )
    end
  end

  def created
    @created ||= resources_to_add.pluck(primary_key.to_sym)
  end

  def ids_added_already_query
    workplace
      .workplace_links
      .where(resource_type: model_class.name, resource_id: query_with_selected_ids)
  end

  def ids_added_already
    WorkerPlugins::SelectColumnWithTypeCast.execute!(
      column_name_to_select: :resource_id,
      column_to_compare_with: model_class.column_for_attribute(:id),
      query: ids_added_already_query
    )
  end

  def model_class
    @model_class ||= query.klass
  end

  def primary_key
    @primary_key ||= resources_to_add.klass.primary_key
  end

  def query_with_selected_ids
    WorkerPlugins::SelectColumnWithTypeCast.execute!(
      column_name_to_select: :id,
      column_to_compare_with: WorkerPlugins::WorkplaceLink.column_for_attribute(:resource_id),
      query:
    )
  end

  def resources_to_add
    @resources_to_add ||= query
      .distinct
      .where
      .not(id: ids_added_already)
  end
end
