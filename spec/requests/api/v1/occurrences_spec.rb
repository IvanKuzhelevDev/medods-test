require "rails_helper"

RSpec.describe "Api::V1::Occurrences", type: :request do
  let(:json) { JSON.parse(response.body) }

  describe "GET /api/v1/occurrences" do
    it "lists occurrences across a date window" do
      create(:task, :daily, recurrence_interval: 1, starts_on: Date.new(2026, 6, 1), title: "Обход")
      get "/api/v1/occurrences", params: { from: "2026-06-01", to: "2026-06-05" }
      expect(response).to have_http_status(:ok)
      expect(json["data"].size).to eq(5)
      expect(json["data"].first["title"]).to eq("Обход")
    end

    it "defaults to the current month when no window is given" do
      get "/api/v1/occurrences"
      expect(response).to have_http_status(:ok)
    end

    it "filters by status" do
      task = create(:task, :daily, recurrence_interval: 1, starts_on: Date.new(2026, 6, 1))
      task.occurrences.create!(occurrence_date: Date.new(2026, 6, 2), status: "done")
      get "/api/v1/occurrences", params: { from: "2026-06-01", to: "2026-06-05", status: "done" }
      expect(json["data"].map { |o| o["date"] }).to eq([ "2026-06-02" ])
    end
  end

  describe "PATCH /api/v1/tasks/:task_id/occurrences/:date" do
    it "marks only that day as done (independent state)" do
      task = create(:task, :daily, recurrence_interval: 1, starts_on: Date.new(2026, 6, 1))
      patch "/api/v1/tasks/#{task.id}/occurrences/2026-06-03", params: { occurrence: { status: "done" } }
      expect(response).to have_http_status(:ok)
      expect(json["status"]).to eq("done")
      expect(json["is_exception"]).to be(true)
      expect(task.occurrences.count).to eq(1) # only this day materialized
    end

    it "reschedules a single occurrence (exception)" do
      task = create(:task, :daily, recurrence_interval: 1, starts_on: Date.new(2026, 6, 1))
      patch "/api/v1/tasks/#{task.id}/occurrences/2026-06-03",
            params: { occurrence: { scheduled_at: "2026-06-03T14:00:00Z" } }
      expect(response).to have_http_status(:ok)
      expect(json["scheduled_at"]).to include("14:00")
    end

    it "returns 422 when the date is not part of the schedule" do
      task = create(:task, :monthly, days_of_month: [ 1 ], starts_on: Date.new(2026, 6, 1))
      patch "/api/v1/tasks/#{task.id}/occurrences/2026-06-02", params: { occurrence: { status: "done" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /api/v1/tasks/:task_id/occurrences/:date" do
    it "cancels only that day" do
      task = create(:task, :daily, recurrence_interval: 1, starts_on: Date.new(2026, 6, 1))
      delete "/api/v1/tasks/#{task.id}/occurrences/2026-06-03"
      expect(response).to have_http_status(:ok)
      expect(json["canceled"]).to be(true)
      expect(json["status"]).to eq("canceled")
    end
  end
end
