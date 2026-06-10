require "rails_helper"

RSpec.describe Recurrence::Generator do
  def dates(task, from, to)
    described_class.new(task).dates_between(from, to)
  end

  describe "once" do
    it "returns the single date if inside the window" do
      task = build(:task, recurrence_type: "once", starts_on: Date.new(2026, 6, 10))
      expect(dates(task, Date.new(2026, 6, 1), Date.new(2026, 6, 30)))
        .to eq([ Date.new(2026, 6, 10) ])
    end

    it "returns nothing if outside the window" do
      task = build(:task, recurrence_type: "once", starts_on: Date.new(2026, 5, 10))
      expect(dates(task, Date.new(2026, 6, 1), Date.new(2026, 6, 30))).to eq([])
    end
  end

  describe "daily" do
    it "returns every day when interval is 1" do
      task = build(:task, :daily, recurrence_interval: 1, starts_on: Date.new(2026, 6, 1))
      result = dates(task, Date.new(2026, 6, 1), Date.new(2026, 6, 5))
      expect(result).to eq((1..5).map { |d| Date.new(2026, 6, d) })
    end

    it "respects an interval and aligns to starts_on" do
      task = build(:task, :daily, recurrence_interval: 3, starts_on: Date.new(2026, 6, 1))
      result = dates(task, Date.new(2026, 6, 2), Date.new(2026, 6, 12))
      expect(result).to eq([ Date.new(2026, 6, 4), Date.new(2026, 6, 7), Date.new(2026, 6, 10) ])
    end

    it "never exceeds ends_on" do
      task = build(:task, :daily, recurrence_interval: 1,
                   starts_on: Date.new(2026, 6, 1), ends_on: Date.new(2026, 6, 3))
      result = dates(task, Date.new(2026, 6, 1), Date.new(2026, 6, 30))
      expect(result).to eq([ Date.new(2026, 6, 1), Date.new(2026, 6, 2), Date.new(2026, 6, 3) ])
    end

    it "stays bounded for an open-ended series (infinity problem)" do
      task = build(:task, :daily, recurrence_interval: 1, starts_on: Date.new(2020, 1, 1), ends_on: nil)
      result = dates(task, Date.new(2026, 6, 1), Date.new(2026, 6, 7))
      expect(result.size).to eq(7)
    end
  end

  describe "monthly" do
    it "returns the listed days each month" do
      task = build(:task, :monthly, days_of_month: [ 1, 15 ], starts_on: Date.new(2026, 6, 1))
      result = dates(task, Date.new(2026, 6, 1), Date.new(2026, 7, 31))
      expect(result).to eq([
        Date.new(2026, 6, 1), Date.new(2026, 6, 15),
        Date.new(2026, 7, 1), Date.new(2026, 7, 15)
      ])
    end

    it "skips invalid days instead of rolling over (Feb 31)" do
      task = build(:task, :monthly, days_of_month: [ 31 ], starts_on: Date.new(2026, 1, 1))
      result = dates(task, Date.new(2026, 1, 1), Date.new(2026, 3, 31))
      expect(result).to eq([ Date.new(2026, 1, 31), Date.new(2026, 3, 31) ]) # no Feb
    end
  end

  describe "specific_dates" do
    it "returns only the listed dates within the window" do
      task = build(:task, :specific,
                   specific_dates: [ Date.new(2026, 6, 3), Date.new(2026, 6, 20), Date.new(2026, 7, 1) ])
      result = dates(task, Date.new(2026, 6, 1), Date.new(2026, 6, 30))
      expect(result).to eq([ Date.new(2026, 6, 3), Date.new(2026, 6, 20) ])
    end
  end

  describe "parity" do
    it "returns only even days when parity is even" do
      task = build(:task, :parity, parity: "even", starts_on: Date.new(2026, 6, 1))
      result = dates(task, Date.new(2026, 6, 1), Date.new(2026, 6, 6))
      expect(result).to eq([ Date.new(2026, 6, 2), Date.new(2026, 6, 4), Date.new(2026, 6, 6) ])
    end

    it "returns only odd days when parity is odd" do
      task = build(:task, :parity, parity: "odd", starts_on: Date.new(2026, 6, 1))
      result = dates(task, Date.new(2026, 6, 1), Date.new(2026, 6, 5))
      expect(result).to eq([ Date.new(2026, 6, 1), Date.new(2026, 6, 3), Date.new(2026, 6, 5) ])
    end
  end

  describe "window cap" do
    it "clamps an oversized window to MAX_WINDOW_DAYS" do
      task = build(:task, :daily, recurrence_interval: 1, starts_on: Date.new(2000, 1, 1))
      result = dates(task, Date.new(2026, 1, 1), Date.new(2099, 1, 1))
      expect(result.size).to eq(Recurrence::Generator::MAX_WINDOW_DAYS + 1)
    end
  end
end
