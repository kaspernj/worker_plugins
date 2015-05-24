class WorkerPlugins::Workplace < ActiveRecord::Base
  has_many :workplace_links, dependent: :destroy

  belongs_to :user, polymorphic: true

  validates_presence_of :name

  def add_links_to_objects(objects)
    require 'active-record-transactioner'

    # Cache inserted objects.
    inserted_ids = load_inserted_ids

    # Add given objects through transactions.
    ActiveRecordTransactioner.new do |trans|
      stream_each(objects) do |object|
        class_name = object.class.name.to_s
        inserted_ids[class_name] ||= {}

        unless inserted_ids[class_name].key?(object.id)
          inserted_ids[class_name][object.id] = true
          link = WorkerPlugins::WorkplaceLink.new(
            workplace: self,
            resource: object
          )
          trans.save!(link)
        end
      end
    end

    return
  end

  def each_resource(args = {})
    count = 0

    links_query = workplace_links.group('worker_plugins_workplace_links.resource_type').order('worker_plugins_workplace_links.id')
    links_query = links_query.where(resource_type: args[:types]) if args[:types]

    links_query.each do |workplace_link|
      constant = Object.const_get(workplace_link.resource_type)
      ids = workplace_links.select(:resource_id).where(resource_type: workplace_link.resource_type).map(&:resource_id)

      ids.each_slice(500) do |ids_slice|
        constant.where(id: ids_slice).each do |resource|
          yield resource
          count += 1
          return if args[:limit] && count >= args[:limit]
        end
      end
    end
  end

  def each_query_for_resources
    workplace_links.group('worker_plugins_workplace_links.resource_type').order('worker_plugins_workplace_links.id').each do |workplace_link|
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

    workplace_links.select(worker_plugins_workplace_links: [:resource_type, :resource_id]).find_each do |workplace_link|
      inserted_ids[workplace_link.resource_type] ||= {}
      inserted_ids[workplace_link.resource_type][workplace_link.resource_id] = true
    end

    return inserted_ids
  end
end
