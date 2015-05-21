class WorkerPlugins::WorkplaceLink < ActiveRecord::Base
  belongs_to :workplace
  belongs_to :resource, polymorphic: true

  validates_presence_of :workplace, :resource
end
