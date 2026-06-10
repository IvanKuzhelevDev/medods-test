module Api
  module V1
    class TagsController < BaseController
      def index
        render json: Tag.order(:name).map { |tag| TagSerializer.new(tag).as_json }
      end

      def create
        tag = Tag.new(tag_params)
        tag.save!
        render json: TagSerializer.new(tag).as_json, status: :created
      end

      def update
        tag = Tag.find(params[:id])
        if tag.update(tag_params)
          render json: TagSerializer.new(tag).as_json
        else
          render_tag_errors(tag)
        end
      end

      def destroy
        tag = Tag.find(params[:id])
        if tag.destroy
          head :no_content
        else
          render_tag_errors(tag)
        end
      end

      private

      def tag_params
        params.require(:tag).permit(:name)
      end

      # System-tag protection halts the callback chain (throw :abort) rather than
      # raising, so update/destroy return false and we surface the model errors.
      def render_tag_errors(tag)
        render json: { error: { message: "Ошибка валидации", details: tag.errors.full_messages } },
               status: :unprocessable_entity
      end
    end
  end
end
