class WorkerPlugins::Workplace < WorkerPlugins::ApplicationRecord
  self.table_name = "worker_plugins_workplaces"

  has_many :workplace_links, dependent: :destroy

  belongs_to :user, polymorphic: true

  validates :name, presence: true

  def each_resource(limit: nil, types: nil)
    count = 0

    links_query = workplace_links.order(:id)
    links_query = links_query.where(resource_type: types) if types
    links_query.find_in_batches do |workplace_links|
      workplace_links.each do |workplace_link|
        yield workplace_link.resource
        count += 1
        return if limit && count >= limit # rubocop:disable Lint/NonLocalExitFromIterator:
      end
    end
  end

  def each_query_for_resources
    workplace_links.group("worker_plugins_workplace_links.resource_type").order("worker_plugins_workplace_links.id").each do |workplace_link|
      resource_type = workplace_link.resource_type
      constant = Object.const_get(resource_type)
      ids = workplace_links.select(:resource_id).where(resource_type: workplace_link.resource_type).map(&:resource_id)

      ids.each_slice(500) do |ids_slice|
        query = constant.where(id: ids_slice)

        yield(query: query, resource_type: resource_type)
      end
    end
  end

  def truncate
    workplace_links.delete_all
  end

private

  def stream_each(list, &blk)
    if list.respond_to?(:find_each)
      list.find_each(&blk)
    else
      list.each(&blk)
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
end
