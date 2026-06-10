require "swagger_helper"

RSpec.describe "Вхождения (календарь)", type: :request do
  path "/api/v1/occurrences" do
    get "Календарь: вхождения за период" do
      tags "Вхождения"
      produces "application/json"
      parameter name: :from, in: :query, required: false, schema: { type: :string, format: "date" },
                description: "Начало окна (по умолчанию — начало текущего месяца)"
      parameter name: :to, in: :query, required: false, schema: { type: :string, format: "date" },
                description: "Конец окна (по умолчанию — конец текущего месяца)"
      parameter name: :status, in: :query, required: false, schema: { type: :string, enum: Task::STATUSES }
      parameter name: :tag, in: :query, required: false, schema: { type: :string }

      response "200", "список вхождений" do
        let(:from) { "2026-06-01" }
        let(:to)   { "2026-06-07" }
        before { create(:task, :daily, recurrence_interval: 1, starts_on: Date.new(2026, 6, 1)) }
        run_test!
      end
    end
  end

  path "/api/v1/tasks/{task_id}/occurrences/{date}" do
    parameter name: :task_id, in: :path, type: :integer, description: "ID задачи (серии)"
    parameter name: :date, in: :path, type: :string, description: "Дата вхождения (YYYY-MM-DD) — якорь слота"

    patch "Изменить один экземпляр (выполнить / перенести / править)" do
      tags "Вхождения"
      consumes "application/json"
      produces "application/json"
      parameter name: :occurrence, in: :body, schema: {
        type: :object,
        properties: {
          occurrence: {
            type: :object,
            properties: {
              status: { type: :string, enum: Task::STATUSES },
              scheduled_at: { type: :string, format: "date-time", description: "Перенос на другое время" },
              title: { type: :string },
              description: { type: :string },
              canceled: { type: :boolean }
            }
          }
        }
      }
      response "200", "экземпляр обновлён" do
        let(:task_id) { create(:task, :daily, recurrence_interval: 1, starts_on: Date.new(2026, 6, 1)).id }
        let(:date) { "2026-06-03" }
        let(:occurrence) { { occurrence: { status: "done" } } }
        run_test!
      end
      response "422", "дата не входит в расписание серии" do
        let(:task_id) { create(:task, :monthly, days_of_month: [ 1 ], starts_on: Date.new(2026, 6, 1)).id }
        let(:date) { "2026-06-02" }
        let(:occurrence) { { occurrence: { status: "done" } } }
        run_test!
      end
    end

    delete "Отменить один экземпляр (пропустить день)" do
      tags "Вхождения"
      produces "application/json"
      response "200", "экземпляр отменён" do
        let(:task_id) { create(:task, :daily, recurrence_interval: 1, starts_on: Date.new(2026, 6, 1)).id }
        let(:date) { "2026-06-03" }
        run_test!
      end
    end
  end
end
