Rails.application.routes.draw do
  root to: "pages#home"

  resources :locations
  resources :members
  resources :pictures
  resources :teams
  resources :users
  resources :weblinks

  resources :current_teams, only: %i[index show create destroy]

  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"

  get "/pictures_only/:id", to: "pictures_only#show", as: "picture_only"

  namespace :admin, module: "admins", constraints: ->(request) { AdminConstraint.matches?(request) } do
    get "", to: "pages#index"
    resources :locations
    resources :members
    resources :pictures
    resources :teams
    resources :users
    resources :weblinks
    get "record_history", to: "record_history#index", as: :record_history

    mount GoodJob::Engine, at: "good_job" # , constraints: ->(request) { AdminConstraint.matches?(request) }
  end

  # catch all unknown routes to NOT throw a FATAL ActionController::RoutingError
  match "*path", to: "application#error_404", via: :all,
    constraints: ->(request) { !request.path_parameters[:path].start_with?("rails/") }
end
