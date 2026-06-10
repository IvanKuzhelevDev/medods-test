require "rails_helper"

RSpec.describe TaskOccurrence, type: :model do
  it "requires an occurrence_date" do
    expect(build(:task_occurrence, occurrence_date: nil)).not_to be_valid
  end

  it "is unique per (task, date)" do
    occ = create(:task_occurrence)
    dup = build(:task_occurrence, task: occ.task, occurrence_date: occ.occurrence_date)
    expect(dup).not_to be_valid
  end

  it "validates status inclusion when present" do
    expect(build(:task_occurrence, status: "bogus")).not_to be_valid
  end

  it "allows a nil status (falls back to series default)" do
    expect(build(:task_occurrence, status: nil)).to be_valid
  end

  it "rejects a date that is not part of the series schedule" do
    task = create(:task, :monthly, days_of_month: [ 1 ], starts_on: Date.new(2026, 6, 1))
    occ  = build(:task_occurrence, task: task, occurrence_date: Date.new(2026, 6, 2))
    expect(occ).not_to be_valid
    expect(occ.errors[:occurrence_date]).to be_present
  end
end
