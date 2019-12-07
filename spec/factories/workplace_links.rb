FactoryBot.define do
  factory :workplace_link, class: "WorkerPlugins::WorkplaceLink" do
    association :resource, factory: :task
    workplace
  end
end
