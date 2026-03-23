FactoryBot.define do
  factory :workplace, class: "WorkerPlugins::Workplace" do
    sequence(:name) { |n| "Workplace #{n}" }
    user

    trait :for_session do
      user { nil }
      sequence(:session_id) { |n| "session-#{n}" }
    end
  end
end
