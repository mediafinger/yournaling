Rails.application.routes.draw do
  root to: "pages#home"

  resources :teams do
    resources :members
    resources :memories
  end

  resources :teams
  resources :users

  namespace :current_team, module: :current_teams do
    resources :locations
    resources :members
    resources :memories
    resources :pictures
    resources :weblinks

    get "/content_visibility/:id/edit", to: "content_visibility#edit", as: "edit_content_visibility"
    patch "/content_visibility/:id", to: "content_visibility#update", as: "content_visibility"
  end

  resources :switch_current_teams, only: %i[index show create destroy]

  get "new_search", to: "searches#new", as: "new_search"
  post "search", to: "searches#create", as: "search"

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
