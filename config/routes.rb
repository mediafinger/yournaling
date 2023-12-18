Rails.application.routes.draw do
  root to: "pages#home"

  resources :pictures
  resources :locations
  resources :members
  resources :teams
  resources :users

  resources :current_teams, only: %i[index show create destroy]

  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"

  get "/pictures_only/:id", to: "pictures_only#show", as: "picture_only" # TODO: replace :id (YID) with urlsafe_id ?!

  # catch all unknown routes to NOT throw a FATAL ActionController::RoutingError
  match "*path", to: "application#error_404", via: :all,
    constraints: ->(request) { !request.path_parameters[:path].start_with?("rails/") }
end
