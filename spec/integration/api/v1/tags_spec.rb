require "swagger_helper"

RSpec.describe "Теги", type: :request do
  path "/api/v1/tags" do
    get "Список тегов" do
      tags "Теги"
      produces "application/json"
      response "200", "список тегов" do
        before { Tag::SYSTEM_NAMES.each { |n| Tag.find_or_create_by!(name: n) { |t| t.system = true } } }
        run_test!
      end
    end

    post "Создать пользовательский тег" do
      tags "Теги"
      consumes "application/json"
      produces "application/json"
      parameter name: :tag, in: :body, schema: {
        type: :object, required: %w[tag],
        properties: { tag: { type: :object, required: %w[name], properties: { name: { type: :string, example: "обход" } } } }
      }
      response "201", "тег создан" do
        let(:tag) { { tag: { name: "обход" } } }
        run_test!
      end
    end
  end

  path "/api/v1/tags/{id}" do
    parameter name: :id, in: :path, type: :integer, description: "ID тега"

    patch "Переименовать тег (системные — запрещено)" do
      tags "Теги"
      consumes "application/json"
      produces "application/json"
      parameter name: :tag, in: :body, schema: {
        type: :object, properties: { tag: { type: :object, properties: { name: { type: :string } } } }
      }
      response "200", "переименован" do
        let(:id) { create(:tag, name: "обход").id }
        let(:tag) { { tag: { name: "обходы" } } }
        run_test!
      end
      response "422", "системный тег изменять нельзя" do
        let(:id) { create(:tag, :system_tag, name: "операции").id }
        let(:tag) { { tag: { name: "хирургия" } } }
        run_test!
      end
    end

    delete "Удалить тег (системные — запрещено)" do
      tags "Теги"
      produces "application/json"
      response "204", "удалён" do
        let(:id) { create(:tag, name: "обход").id }
        run_test!
      end
      response "422", "системный тег удалять нельзя" do
        let(:id) { create(:tag, :system_tag, name: "звонок").id }
        run_test!
      end
    end
  end

  path "/api/v1/tasks/{task_id}/tags" do
    parameter name: :task_id, in: :path, type: :integer, description: "ID задачи"

    post "Добавить тег задаче" do
      tags "Теги"
      consumes "application/json"
      produces "application/json"
      parameter name: :body, in: :body, schema: {
        type: :object, required: %w[tag_id], properties: { tag_id: { type: :integer } }
      }
      response "201", "тег добавлен" do
        let(:task_id) { create(:task).id }
        let(:body) { { tag_id: create(:tag, name: "обход").id } }
        run_test!
      end
    end
  end

  path "/api/v1/tasks/{task_id}/tags/{id}" do
    parameter name: :task_id, in: :path, type: :integer, description: "ID задачи"
    parameter name: :id, in: :path, type: :integer, description: "ID тега"

    delete "Снять тег с задачи" do
      tags "Теги"
      response "204", "тег снят" do
        let(:task) { create(:task) }
        let(:tag) { create(:tag, name: "обход") }
        let(:task_id) { task.id }
        let(:id) { tag.id }
        before { task.tags << tag }
        run_test!
      end
    end
  end
end
