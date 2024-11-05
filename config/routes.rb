Rails.application.routes.draw do
  root to: "pages#show"

  get "up" => "health#show", as: :rails_health_check

  resources :teams, except: %i[show]
  resources :users

  resources :teams, module: :teams do
    get "", to: "pages#show", as: "home"

    resources :members, only: %i[index show]
    resources :memories, only: %i[index show]

    resources :locations, only: %i[show]
    resources :pictures, only: %i[show]
    resources :thoughts, only: %i[show]
    resources :weblinks, only: %i[show]

    get "/pictures_only/:id", to: "pictures_only#show", as: "picture_only"
  end

  namespace :current_team, module: :current_teams do
    get "", to: "pages#show", as: "home"

    resources :locations
    resources :members
    resources :memories
    resources :pictures
    resources :thoughts
    resources :weblinks

    get "/content_visibility/:id/edit", to: "content_visibility#edit", as: "edit_content_visibility"
    patch "/content_visibility/:id", to: "content_visibility#update", as: "content_visibility"

    get "new_search", to: "searches#new", as: "new_search"
    post "search", to: "searches#create", as: "search"
  end

  resources :switch_current_teams, only: %i[index show create destroy]

  # Login Controller
  resources :logins, only: %i[index destroy], as: :login_records
  # Session Controller
  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"

  namespace :admin, module: "admins", constraints: ->(request) { AdminConstraint.matches?(request) } do
    get "", to: "pages#show", as: "home"
    resources :locations
    resources :members
    # resources :memories # TODO
    resources :pictures
    resources :teams
    resources :users
    resources :thoughts
    resources :weblinks
    get "record_history", to: "record_history#index", as: :record_history

    get "new_filter", to: "filters#new", as: "new_filter"
    post "filter", to: "filters#create", as: "filter"

    # NOTE: we setup MissionControl to inherit from our AdminController to only give admins access
    mount MissionControl::Jobs::Engine, at: "/jobs"
  end

  # catch all unknown routes to NOT throw a FATAL ActionController::RoutingError
  match "*path", to: "application#error_404", via: :all,
    constraints: ->(request) { !request.path_parameters[:path].start_with?("rails/") }
end
