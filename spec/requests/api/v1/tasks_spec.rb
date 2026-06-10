require "rails_helper"

RSpec.describe "Api::V1::Tasks", type: :request do
  let(:json) { JSON.parse(response.body) }

  describe "POST /api/v1/tasks" do
    it "creates a one-off task" do
      post "/api/v1/tasks", params: {
        task: { title: "Подготовить отчёт", description: "Квартальный",
                recurrence_type: "once", starts_on: "2026-06-10", status: "new" }
      }
      expect(response).to have_http_status(:created)
      expect(json["title"]).to eq("Подготовить отчёт")
      expect(json["recurrence"]["type"]).to eq("once")
    end

    it "creates a recurring task with tags" do
      tag = create(:tag, name: "звонок")
      post "/api/v1/tasks", params: {
        task: { title: "Обзвон пациентов", recurrence_type: "daily",
                recurrence_interval: 1, starts_on: "2026-06-01", tag_ids: [ tag.id ] }
      }
      expect(response).to have_http_status(:created)
      expect(json["tags"].first["name"]).to eq("звонок")
    end

    it "returns 422 on invalid recurrence params" do
      post "/api/v1/tasks", params: {
        task: { title: "Bad", recurrence_type: "daily", recurrence_interval: 0,
                starts_on: "2026-06-01" }
      }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json["error"]).to be_present
    end
  end

  describe "GET /api/v1/tasks" do
    it "lists tasks filtered by status" do
      create(:task, status: "new", title: "A")
      create(:task, status: "done", title: "B")
      get "/api/v1/tasks", params: { status: "done" }
      expect(response).to have_http_status(:ok)
      expect(json["data"].map { |t| t["title"] }).to eq([ "B" ])
    end
  end

  describe "GET /api/v1/tasks/:id" do
    it "shows a task" do
      task = create(:task, title: "Обход")
      get "/api/v1/tasks/#{task.id}"
      expect(response).to have_http_status(:ok)
      expect(json["title"]).to eq("Обход")
    end

    it "returns 404 for a missing task" do
      get "/api/v1/tasks/0"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /api/v1/tasks/:id" do
    it "updates a task" do
      task = create(:task, title: "Старое")
      patch "/api/v1/tasks/#{task.id}", params: { task: { title: "Новое" } }
      expect(response).to have_http_status(:ok)
      expect(json["title"]).to eq("Новое")
    end
  end

  describe "DELETE /api/v1/tasks/:id" do
    it "deletes a task" do
      task = create(:task)
      delete "/api/v1/tasks/#{task.id}"
      expect(response).to have_http_status(:no_content)
      expect(Task.exists?(task.id)).to be(false)
    end
  end
end
