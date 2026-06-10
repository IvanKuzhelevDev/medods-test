require "swagger_helper"

RSpec.describe "Задачи", type: :request do
  path "/api/v1/tasks" do
    get "Список задач (определений серий)" do
      tags "Задачи"
      produces "application/json"
      parameter name: :status, in: :query, required: false,
                schema: { type: :string, enum: Task::STATUSES }, description: "Фильтр по статусу"
      parameter name: :tag, in: :query, required: false,
                schema: { type: :string }, description: "Фильтр по имени тега"

      response "200", "список задач" do
        before { create(:task) }
        run_test!
      end
    end

    post "Создать задачу" do
      tags "Задачи"
      consumes "application/json"
      produces "application/json"
      parameter name: :task, in: :body, schema: {
        type: :object,
        required: %w[task],
        properties: {
          task: {
            type: :object,
            required: %w[title recurrence_type],
            properties: {
              title: { type: :string, example: "Обзвон пациентов" },
              description: { type: :string },
              status: { type: :string, enum: Task::STATUSES },
              recurrence_type: { type: :string, enum: Task::RECURRENCE_TYPES },
              recurrence_interval: { type: :integer, example: 1, description: "для daily: каждый n-й день" },
              days_of_month: { type: :array, items: { type: :integer }, description: "для monthly: числа 1..31" },
              specific_dates: { type: :array, items: { type: :string, format: "date" } },
              parity: { type: :string, enum: Task::PARITIES, description: "для parity: чётные/нечётные дни" },
              starts_on: { type: :string, format: "date", example: "2026-06-01" },
              ends_on: { type: :string, format: "date", description: "null = бессрочно" },
              due_time: { type: :string, example: "10:00" },
              tag_ids: { type: :array, items: { type: :integer } }
            }
          }
        }
      }

      response "201", "задача создана" do
        let(:task) { { task: { title: "Обзвон", recurrence_type: "daily", recurrence_interval: 1, starts_on: "2026-06-01" } } }
        run_test!
      end

      response "422", "ошибка валидации" do
        let(:task) { { task: { title: "", recurrence_type: "daily" } } }
        run_test!
      end
    end
  end

  path "/api/v1/tasks/{id}" do
    parameter name: :id, in: :path, type: :integer, description: "ID задачи"

    get "Показать задачу" do
      tags "Задачи"
      produces "application/json"
      response "200", "задача" do
        let(:id) { create(:task).id }
        run_test!
      end
      response "404", "не найдена" do
        let(:id) { 0 }
        run_test!
      end
    end

    patch "Обновить задачу (всю серию)" do
      tags "Задачи"
      consumes "application/json"
      produces "application/json"
      parameter name: :task, in: :body, schema: {
        type: :object,
        properties: {
          task: {
            type: :object,
            properties: {
              title: { type: :string },
              description: { type: :string },
              status: { type: :string, enum: Task::STATUSES }
            }
          }
        }
      }
      response "200", "обновлена" do
        let(:id) { create(:task).id }
        let(:task) { { task: { title: "Новое название" } } }
        run_test!
      end
    end

    delete "Удалить задачу" do
      tags "Задачи"
      response "204", "удалена" do
        let(:id) { create(:task).id }
        run_test!
      end
    end
  end
end
