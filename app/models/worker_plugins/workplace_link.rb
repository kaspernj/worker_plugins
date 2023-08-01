class WorkerPlugins::WorkplaceLink < WorkerPlugins::ApplicationRecord
  self.table_name = "worker_plugins_workplace_links"

  belongs_to :workplace
  belongs_to :resource, polymorphic: true

  validates :resource_id, uniqueness: {scope: [:resource_type, :workplace_id]}
end
