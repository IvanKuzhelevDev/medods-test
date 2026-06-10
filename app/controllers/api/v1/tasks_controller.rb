module Api
  module V1
    class TasksController < BaseController
      def index
        scope = Task.with_status(params[:status])
                    .tagged_with(params[:tag])
                    .includes(:tags)
                    .order(:starts_on, :id)

        pagy, tasks = pagy(scope)
        render json: {
          data: tasks.map { |task| TaskSerializer.new(task).as_json },
          meta: pagination_meta(pagy)
        }
      end

      def show
        render json: TaskSerializer.new(Task.find(params[:id])).as_json
      end

      def create
        task = Task.new(task_params)
        task.save!
        render json: TaskSerializer.new(task).as_json, status: :created
      end

      def update
        task = Task.find(params[:id])
        task.update!(task_params)
        render json: TaskSerializer.new(task).as_json
      end

      def destroy
        Task.find(params[:id]).destroy!
        head :no_content
      end

      private

      def task_params
        params.require(:task).permit(
          :title, :description, :status, :recurrence_type, :recurrence_interval,
          :parity, :starts_on, :ends_on, :due_time,
          days_of_month: [], specific_dates: [], tag_ids: []
        )
      end
    end
  end
end
