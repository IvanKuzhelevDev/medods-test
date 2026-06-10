require "rails_helper"

RSpec.describe "Api::V1::Tags", type: :request do
  let(:json) { JSON.parse(response.body) }

  before { Tag::SYSTEM_NAMES.each { |n| Tag.find_or_create_by!(name: n) { |t| t.system = true } } }

  it "lists tags including system tags" do
    get "/api/v1/tags"
    expect(response).to have_http_status(:ok)
    expect(json.map { |t| t["name"] }).to include("операции", "звонок", "отчётность")
  end

  it "creates a custom tag" do
    post "/api/v1/tags", params: { tag: { name: "обход" } }
    expect(response).to have_http_status(:created)
    expect(json["system"]).to be(false)
  end

  it "forbids renaming a system tag" do
    tag = Tag.find_by(name: "операции")
    patch "/api/v1/tags/#{tag.id}", params: { tag: { name: "хирургия" } }
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "forbids deleting a system tag" do
    tag = Tag.find_by(name: "звонок")
    delete "/api/v1/tags/#{tag.id}"
    expect(response).to have_http_status(:unprocessable_entity)
    expect(Tag.exists?(tag.id)).to be(true)
  end

  describe "attach / detach" do
    it "attaches a tag to a task" do
      task = create(:task)
      tag  = create(:tag, name: "обход")
      post "/api/v1/tasks/#{task.id}/tags", params: { tag_id: tag.id }
      expect(response).to have_http_status(:created)
      expect(task.reload.tags).to include(tag)
    end

    it "detaches a tag from a task" do
      task = create(:task)
      tag  = create(:tag, name: "обход")
      task.tags << tag
      delete "/api/v1/tasks/#{task.id}/tags/#{tag.id}"
      expect(response).to have_http_status(:no_content)
      expect(task.reload.tags).not_to include(tag)
    end
  end
end
