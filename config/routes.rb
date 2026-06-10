Rails.application.routes.draw do
  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"
  # Health check (used by Docker / load balancers).
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      # Task definitions / series.
      resources :tasks do
        # A single occurrence is addressed by its anchor date (YYYY-MM-DD).
        resources :occurrences, only: %i[update destroy], param: :date,
                                constraints: { date: /\d{4}-\d{2}-\d{2}/ }
        # Attach / detach a tag to a task.
        resources :tags, only: %i[create destroy], controller: :task_tags
      end

      # Calendar view across tasks (the tracker list, filtered by date/status/tag).
      resources :occurrences, only: %i[index]

      # Tag catalogue.
      resources :tags, only: %i[index create update destroy]
    end
  end
end
