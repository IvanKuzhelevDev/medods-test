FactoryBot.define do
  factory :task do
    sequence(:title) { |n| "Задача #{n}" }
    description { "Описание" }
    status { "new" }
    recurrence_type { "once" }
    starts_on { Date.new(2026, 6, 1) }

    trait :daily do
      recurrence_type { "daily" }
      recurrence_interval { 1 }
    end

    trait :monthly do
      recurrence_type { "monthly" }
      days_of_month { [ 1, 15 ] }
    end

    trait :specific do
      recurrence_type { "specific_dates" }
      specific_dates { [ Date.new(2026, 6, 3), Date.new(2026, 6, 10) ] }
      starts_on { nil }
    end

    trait :parity do
      recurrence_type { "parity" }
      parity { "even" }
    end
  end
end
