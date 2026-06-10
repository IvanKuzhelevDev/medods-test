require "rails_helper"

RSpec.describe "Task <-> Tag association", type: :model do
  it "attaches tags to a task many-to-many" do
    task = create(:task)
    tag  = create(:tag, name: "обход")
    task.tags << tag
    expect(task.reload.tags).to include(tag)
    expect(tag.reload.tasks).to include(task)
  end

  it "prevents duplicate task/tag pairs via model validation" do
    task = create(:task)
    tag  = create(:tag, name: "обход")
    task.tags << tag
    expect(task.task_tags.build(tag: tag)).not_to be_valid
  end

  it "enforces uniqueness at the database level too" do
    task = create(:task)
    tag  = create(:tag, name: "обход")
    task.tags << tag
    expect { task.task_tags.build(tag: tag).save!(validate: false) }
      .to raise_error(ActiveRecord::RecordNotUnique)
  end
end
