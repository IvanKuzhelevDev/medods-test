FactoryBot.define do
  factory :task_occurrence do
    association :task, :daily
    occurrence_date { Date.new(2026, 6, 1) }
    status { "done" }
  end
end
