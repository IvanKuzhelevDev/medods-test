module Api
  module V1
    # Attach / detach a tag to a task.
    class TaskTagsController < BaseController
      def create
        task = Task.find(params[:task_id])
        tag  = Tag.find(params[:tag_id])
        task.task_tags.find_or_create_by!(tag: tag)
        render json: TaskSerializer.new(task.reload).as_json, status: :created
      end

      def destroy
        task = Task.find(params[:task_id])
        task.task_tags.where(tag_id: params[:id]).destroy_all
        head :no_content
      end
    end
  end
end
