class WorkerPlugins::Workplace < WorkerPlugins::ApplicationRecord
  self.table_name = "worker_plugins_workplaces"

  has_many :workplace_links, dependent: :destroy

  belongs_to :user, polymorphic: WorkerPlugins::UserRelationshipPolymorphic.execute!, optional: true

  validates :name, presence: true
  validate :validate_owner

  def each_resource(limit: nil, types: nil)
    count = 0

    links_query = workplace_links.order(:id)
    links_query = links_query.where(resource_type: types) if types
    links_query.find_in_batches do |workplace_links|
      resources_by_type_and_id = load_resources_by_type_and_id(workplace_links)

      workplace_links.each do |workplace_link|
        resource = resources_by_type_and_id
          .fetch(workplace_link.resource_type)[workplace_link.resource_id.to_s]
        next unless resource

        yield resource
        count += 1
        return if limit && count >= limit # rubocop:disable Lint/NonLocalExitFromIterator
      end
    end
  end

  def each_query_for_resources
    resource_ids_by_type = workplace_links
      .order(:id)
      .pluck(:resource_type, :resource_id)
      .each_with_object({}) do |(resource_type, resource_id), grouped_ids|
        grouped_ids[resource_type] ||= []
        grouped_ids[resource_type] << resource_id
      end

    resource_ids_by_type.each do |resource_type, ids|
      constant = Object.const_get(resource_type)

      ids.each_slice(500) do |ids_slice|
        yield(query: constant.where(id: ids_slice), resource_type:)
      end
    end
  end

  def truncate
    workplace_links.delete_all
  end

private

  def stream_each(list, &)
    if list.respond_to?(:find_each)
      list.find_each(&)
    else
      list.each(&)
    end
  end

  def load_inserted_ids
    inserted_ids = {}

    workplace_links.select(:id, :resource_type, :resource_id).find_each do |workplace_link|
      inserted_ids[workplace_link.resource_type] ||= {}
      inserted_ids[workplace_link.resource_type][workplace_link.resource_id] = true
    end

    inserted_ids
  end

  def load_resources_by_type_and_id(workplace_links)
    workplace_links
      .group_by(&:resource_type)
      .transform_values do |links_for_type|
        resource_class = Object.const_get(links_for_type.first.resource_type)
        resource_ids = links_for_type.map(&:resource_id)

        resource_class
          .where(id: resource_ids)
          .index_by { |resource| resource.id.to_s }
      end
  end

  def validate_owner
    if user.present? && session_id.present?
      errors.add(:base, "Workplace can't belong to both a user and a session")
    elsif user.blank? && session_id.blank?
      errors.add(:base, "Workplace must belong to a user or a session")
    end
  end
end
