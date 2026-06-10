class TaskSerializer
  def initialize(task) = @task = task

  def as_json(*)
    {
      id: @task.id,
      title: @task.title,
      description: @task.description,
      status: @task.status,
      due_time: @task.due_time&.strftime("%H:%M"),
      recurrence: {
        type: @task.recurrence_type,
        interval: @task.recurrence_interval,
        days_of_month: @task.days_of_month,
        specific_dates: @task.specific_dates,
        parity: @task.parity,
        starts_on: @task.starts_on,
        ends_on: @task.ends_on
      },
      tags: @task.tags.map { |tag| TagSerializer.new(tag).as_json },
      created_at: @task.created_at,
      updated_at: @task.updated_at
    }
  end
end
