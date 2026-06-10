class OccurrenceSerializer
  # Serializes an Occurrences::View (virtual or materialized occurrence).
  def initialize(view) = @view = view

  def as_json(*)
    {
      task_id: @view.task.id,
      date: @view.date,
      status: @view.status,
      scheduled_at: @view.scheduled_at,
      title: @view.title,
      description: @view.description,
      canceled: @view.canceled,
      is_exception: @view.exception,
      tags: @view.tags.map { |tag| TagSerializer.new(tag).as_json }
    }
  end
end
