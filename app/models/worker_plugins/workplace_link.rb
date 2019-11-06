class WorkerPlugins::WorkplaceLink < ApplicationRecord
  self.table_name = "worker_plugins_workplace_links"

  belongs_to :workplace
  belongs_to :resource, polymorphic: true

  validates :workplace, :resource, presence: true
end
