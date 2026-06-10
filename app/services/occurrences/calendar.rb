module Occurrences
  # Projects a date window into a flat, sorted list of occurrence views across
  # tasks: virtual occurrences generated from each task's rule, overlaid with any
  # materialized exceptions (status changes, reschedules, cancellations).
  class Calendar
    def initialize(scope: Task.all, from:, to:, status: nil, tag: nil)
      @scope  = scope
      @from   = from
      @to     = to
      @status = status.presence
      @tag    = tag.presence
    end

    def occurrences
      # NOTE (scaling, reviewed): occurrences are expanded for EVERY task in scope
      # before pagination — cost is O(tasks * window) per request. Fine at this scale;
      # for large datasets narrow @scope before expansion or materialize a rolling
      # horizon in a background job.
      tasks = @scope.includes(:tags, :occurrences)
      tasks = tasks.tagged_with(@tag) if @tag

      views = tasks.flat_map { |task| views_for(task) }
      views = views.select { |view| view.status == @status } if @status
      # NOTE (reviewed nit): sort key mixes scheduled_at (UTC) with date.to_time
      # (local) — harmless within a day under the single-timezone assumption.
      views.sort_by { |view| [ view.scheduled_at || view.date.to_time, view.task.id ] }
    end

    private

    def views_for(task)
      overrides = task.occurrences.index_by(&:occurrence_date)
      Recurrence::Generator.new(task).dates_between(@from, @to).map do |date|
        build_view(task, date, overrides[date])
      end
    end

    def build_view(task, date, override)
      View.new(
        task: task,
        date: date,
        status: override&.status || task.status,
        scheduled_at: override&.scheduled_at || default_scheduled_at(task, date),
        title: (override&.title).presence || task.title,
        description: (override&.description).presence || task.description,
        canceled: override&.canceled || false,
        exception: override.present?,
        tags: task.tags.to_a
      )
    end

    def default_scheduled_at(task, date)
      return nil if task.due_time.blank?

      Time.utc(date.year, date.month, date.day, task.due_time.hour, task.due_time.min)
    end
  end
end
