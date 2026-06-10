require "rails_helper"

RSpec.describe Task, type: :model do
  it "requires a title" do
    expect(build(:task, title: nil)).not_to be_valid
  end

  it "validates status inclusion" do
    expect(build(:task, status: "bogus")).not_to be_valid
  end

  it "validates recurrence_type inclusion" do
    expect(build(:task, recurrence_type: "weekly")).not_to be_valid
  end

  describe "recurrence parameter validation" do
    it "requires a positive interval for daily" do
      expect(build(:task, :daily, recurrence_interval: 0)).not_to be_valid
    end

    it "requires days_of_month within 1..31 for monthly" do
      expect(build(:task, :monthly, days_of_month: [ 0, 32 ])).not_to be_valid
      expect(build(:task, :monthly, days_of_month: [ 1, 31 ])).to be_valid
    end

    it "requires non-empty specific_dates" do
      expect(build(:task, :specific, specific_dates: [])).not_to be_valid
    end

    it "requires parity in even/odd" do
      expect(build(:task, :parity, parity: "weird")).not_to be_valid
    end

    it "requires ends_on to be on or after starts_on" do
      expect(build(:task, :daily, starts_on: Date.new(2026, 6, 10), ends_on: Date.new(2026, 6, 1)))
        .not_to be_valid
    end
  end
end
