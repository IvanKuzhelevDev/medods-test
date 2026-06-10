module Recurrence
  # Pure date-math engine. Given a Task (a recurrence rule) and a date window,
  # returns the concrete dates the task is scheduled on within that window.
  #
  # Nothing is persisted: occurrences are computed on demand, which is how the
  # "infinity problem" (open-ended series) is solved — the window always bounds
  # the result, and an extra hard cap (MAX_WINDOW_DAYS) prevents abuse.
  class Generator
    MAX_WINDOW_DAYS = 366

    def initialize(task)
      @task = task
    end

    # @return [Array<Date>] sorted scheduled dates within [from, to]
    def dates_between(from, to)
      to = [ to, from + MAX_WINDOW_DAYS ].min
      return [] if from > to

      case @task.recurrence_type
      when "once"           then once_dates(from, to)
      when "daily"          then daily_dates(from, to)
      when "monthly"        then monthly_dates(from, to)
      when "specific_dates" then specific_dates(from, to)
      when "parity"         then parity_dates(from, to)
      else []
      end
    end

    private

    # Intersect the query window with the series' own [starts_on, ends_on].
    def effective_range(from, to)
      lower = [ @task.starts_on, from ].compact.max
      upper = @task.ends_on ? [ @task.ends_on, to ].min : to
      [ lower, upper ]
    end

    def once_dates(from, to)
      d = @task.starts_on
      d && d.between?(from, to) ? [ d ] : []
    end

    def daily_dates(from, to)
      lower, upper = effective_range(from, to)
      return [] if lower.nil? || lower > upper

      step = @task.recurrence_interval || 1
      offset = (lower - @task.starts_on).to_i
      remainder = offset % step
      first = remainder.zero? ? lower : lower + (step - remainder)
      (first..upper).step(step).to_a
    end

    def monthly_dates(from, to)
      lower, upper = effective_range(from, to)
      return [] if lower.nil? || lower > upper

      days = Array(@task.days_of_month).uniq
      result = []
      each_month(lower, upper) do |year, month|
        days.each do |day|
          next unless Date.valid_date?(year, month, day)

          d = Date.new(year, month, day)
          result << d if d.between?(lower, upper)
        end
      end
      result.sort
    end

    def specific_dates(from, to)
      lower, upper = effective_range(from, to)
      Array(@task.specific_dates).select { |d| d.between?(lower, upper) }.sort
    end

    def parity_dates(from, to)
      lower, upper = effective_range(from, to)
      return [] if lower.nil? || lower > upper

      want_even = @task.parity == "even"
      (lower..upper).select { |d| d.day.even? == want_even }
    end

    def each_month(from, to)
      cursor = from.beginning_of_month
      while cursor <= to
        yield cursor.year, cursor.month
        cursor = cursor.next_month
      end
    end
  end
end
