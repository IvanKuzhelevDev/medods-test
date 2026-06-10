require "rails_helper"

RSpec.describe Occurrences::Calendar do
  let(:from) { Date.new(2026, 6, 1) }
  let(:to)   { Date.new(2026, 6, 7) }

  def views(**opts)
    described_class.new(scope: Task.all, from: from, to: to, **opts).occurrences
  end

  it "expands a daily series into one view per day" do
    create(:task, :daily, recurrence_interval: 1, starts_on: from, title: "Обход")
    result = views
    expect(result.size).to eq(7)
    expect(result.map(&:date)).to eq((1..7).map { |d| Date.new(2026, 6, d) })
    expect(result).to all(have_attributes(status: "new", exception: false))
  end

  it "overlays a materialized occurrence's independent status" do
    task = create(:task, :daily, recurrence_interval: 1, starts_on: from)
    create(:task_occurrence, task: task, occurrence_date: Date.new(2026, 6, 3), status: "done")

    result = views
    done  = result.find { |v| v.date == Date.new(2026, 6, 3) }
    other = result.find { |v| v.date == Date.new(2026, 6, 4) }

    expect(done.status).to eq("done")
    expect(done.exception).to be(true)
    expect(other.status).to eq("new") # neighbours unaffected
  end

  it "reflects a rescheduled time on the exception view" do
    task = create(:task, :daily, recurrence_interval: 1, starts_on: from)
    moved_at = Time.utc(2026, 6, 3, 14, 0)
    create(:task_occurrence, task: task, occurrence_date: Date.new(2026, 6, 3), scheduled_at: moved_at)

    view = views.find { |v| v.date == Date.new(2026, 6, 3) }
    expect(view.scheduled_at).to eq(moved_at)
  end

  it "marks a canceled occurrence" do
    task = create(:task, :daily, recurrence_interval: 1, starts_on: from)
    create(:task_occurrence, task: task, occurrence_date: Date.new(2026, 6, 3),
                             canceled: true, status: "canceled")

    view = views.find { |v| v.date == Date.new(2026, 6, 3) }
    expect(view.canceled).to be(true)
  end

  it "filters by effective status" do
    task = create(:task, :daily, recurrence_interval: 1, starts_on: from)
    create(:task_occurrence, task: task, occurrence_date: Date.new(2026, 6, 3), status: "done")

    expect(views(status: "done").map(&:date)).to eq([ Date.new(2026, 6, 3) ])
  end

  it "filters by tag" do
    tagged = create(:task, :daily, recurrence_interval: 1, starts_on: from)
    create(:task, :daily, recurrence_interval: 1, starts_on: from) # untagged
    tag = create(:tag, name: "обход")
    tagged.tags << tag

    result = views(tag: "обход")
    expect(result.map(&:task).uniq).to eq([ tagged ])
  end
end
