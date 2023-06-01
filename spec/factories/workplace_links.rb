FactoryBot.define do
  factory :workplace_link, class: "WorkerPlugins::WorkplaceLink" do
    resource factory: %i[task]
    workplace
  end
end
