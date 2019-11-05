class WorkerPlugins::WorkplaceLink < ApplicationRecord
  belongs_to :workplace
  belongs_to :resource, polymorphic: true

  validates :workplace, :resource, presence: true
end
