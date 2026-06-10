require "rails_helper"

RSpec.describe Tag, type: :model do
  it "requires a name" do
    expect(build(:tag, name: nil)).not_to be_valid
  end

  it "enforces case-insensitive uniqueness" do
    create(:tag, name: "Операции")
    expect(build(:tag, name: "операции")).not_to be_valid
  end

  it "allows creating and editing a custom tag" do
    tag = create(:tag, name: "обход")
    expect(tag.update(name: "обходы")).to be(true)
  end

  it "forbids renaming a system tag" do
    tag = create(:tag, :system_tag, name: "операции")
    expect(tag.update(name: "хирургия")).to be(false)
    expect(tag.errors[:base]).to be_present
  end

  it "forbids destroying a system tag" do
    tag = create(:tag, :system_tag, name: "звонок")
    expect(tag.destroy).to be(false)
    expect(Tag.exists?(tag.id)).to be(true)
  end
end
