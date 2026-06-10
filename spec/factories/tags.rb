FactoryBot.define do
  factory :tag do
    sequence(:name) { |n| "tag-#{n}" }
    system { false }

    trait :system_tag do
      system { true }
    end
  end
end
