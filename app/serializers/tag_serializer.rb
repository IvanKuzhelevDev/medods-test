class TagSerializer
  def initialize(tag) = @tag = tag

  def as_json(*)
    { id: @tag.id, name: @tag.name, system: @tag.system }
  end
end
