FactoryBot.define do
  factory :workplace, class: WorkerPlugins::Workplace do
    sequence(:name) { |n| "Workplace #{n}" }
  end
end
