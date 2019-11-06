FactoryBot.define do
  factory :workplace do
    sequence(:name) { |n| "Workplace #{n}" }
  end
end
