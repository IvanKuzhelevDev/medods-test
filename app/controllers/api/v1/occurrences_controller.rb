module Api
  module V1
    class OccurrencesController < BaseController
      # Calendar view across all tasks for a bounded window (the tracker list).
      def index
        from = parse_date(params[:from]) || Date.current.beginning_of_month
        to   = parse_date(params[:to]) || Date.current.end_of_month

        views = Occurrences::Calendar.new(
          scope: Task.all, from: from, to: to,
          status: params[:status], tag: params[:tag]
        ).occurrences

        pagy, page = pagy_array(views)
        render json: {
          data: page.map { |view| OccurrenceSerializer.new(view).as_json },
          meta: pagination_meta(pagy)
        }
      end

      # Update one occurrence: complete it, reschedule it (time-of-day), or edit it for
      # that day. NOTE (reviewed scope): reschedule changes scheduled_at only and keeps
      # the anchor occurrence_date; moving an instance to a DIFFERENT calendar day
      # (e.g. shift Wed -> Thu) is intentionally out of scope (the optional bonus).
      def update
        task = Task.find(params[:task_id])
        occurrence = materialize(task, params[:date])
        occurrence.assign_attributes(occurrence_params)
        occurrence.save!
        render json: OccurrenceSerializer.new(view_for(task, occurrence.occurrence_date)).as_json
      rescue Date::Error
        render_invalid_date
      end

      # Cancel just this occurrence ("skip today") — leaves the rest of the series intact.
      def destroy
        task = Task.find(params[:task_id])
        occurrence = materialize(task, params[:date])
        occurrence.update!(canceled: true, status: "canceled")
        render json: OccurrenceSerializer.new(view_for(task, occurrence.occurrence_date)).as_json
      rescue Date::Error
        render_invalid_date
      end

      private

      def materialize(task, raw_date)
        task.occurrences.find_or_initialize_by(occurrence_date: Date.iso8601(raw_date))
      end

      # Build the response through the same projection used by the calendar, so a
      # single occurrence is represented identically everywhere.
      def view_for(task, date)
        Occurrences::Calendar.new(scope: Task.where(id: task.id), from: date, to: date)
                             .occurrences.first
      end

      def occurrence_params
        params.require(:occurrence).permit(:status, :scheduled_at, :title, :description, :canceled)
      end

      def parse_date(value)
        value.present? ? Date.iso8601(value) : nil
      rescue Date::Error
        nil
      end

      def render_invalid_date
        render json: { error: { message: "Некорректная дата" } }, status: :bad_request
      end
    end
  end
end
