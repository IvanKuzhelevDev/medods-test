module Api
  module V1
    # Base controller for all v1 API endpoints.
    # Centralises error handling (consistent JSON envelope) and pagination.
    class BaseController < ActionController::API
      include Pagy::Backend

      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
      rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable
      rescue_from ActionController::ParameterMissing, with: :render_bad_request

      private

      def render_not_found(error)
        render json: { error: { message: "Запись не найдена", details: error.message } },
               status: :not_found
      end

      def render_unprocessable(error)
        render json: { error: { message: "Ошибка валидации", details: error.record.errors.full_messages } },
               status: :unprocessable_entity
      end

      def render_bad_request(error)
        render json: { error: { message: "Некорректный запрос", details: error.message } },
               status: :bad_request
      end

      def pagination_meta(pagy)
        { page: pagy.page, items: pagy.limit, count: pagy.count, pages: pagy.pages }
      end
    end
  end
end
