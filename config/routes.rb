Rails.application.routes.draw do
  root to: "pages#show"
  get "check_newer", to: "pages#check_newer", as: :check_newer_pages
  get "newer", to: "pages#newer", as: :newer_pages

  get "up" => "health#show", as: :rails_health_check

  resources :teams, except: %i[show]
  # No :new / :create here on purpose: self-service signup lives in RegistrationsController, which
  # is the only path that sends the verification mail. A second, quieter way to create a User would
  # inevitably drift out of that guarantee.
  resources :users, only: %i[index show edit update destroy]
  get "user_password/new", to: "user_passwords#new", as: :new_user_password
  post "user_password", to: "user_passwords#create", as: :user_password
  get "user_password/edit/:token", to: "user_passwords#edit", as: :edit_user_password
  patch "user_password/edit/:token", to: "user_passwords#update"

  # NOTE: "email_verification/new" must stay above "email_verification/:token", or "new" is
  # swallowed as a token. Both must stay above the "*path" catch-all at the bottom of this file.
  get "email_verification/new", to: "email_verifications#new", as: :new_email_verification
  post "email_verification", to: "email_verifications#create", as: :email_verification
  get "email_verification/:token", to: "email_verifications#show", as: :show_email_verification

  get "search", to: "searches#new", as: :new_search
  post "search", to: "searches#create", as: :search

  resources :teams, module: :teams do
    get "", to: "pages#show", as: "home"

    resources :chronicles, only: %i[index show]
    resources :members, only: %i[index show]
    resources :memories, only: %i[index show]

    resources :locations, only: %i[show]
    resources :pictures, only: %i[show]
    resources :thoughts, only: %i[show]
    resources :weblinks, only: %i[show]

    get "/pictures_only/:id", to: "pictures_only#show", as: "picture_only"
  end

  scope ActiveStorage.routes_prefix do
    get "/blobs/proxy/:signed_id/*filename" => "active_storage/authorized_blobs#show"
    get "/representations/proxy/:signed_blob_id/:variation_key/*filename" => "active_storage/authorized_representations#show"
  end

  namespace :current_team, module: :current_teams do
    get "", to: "pages#show", as: "home"
    get "check_newer", to: "pages#check_newer", as: "check_newer_pages"
    get "newer", to: "pages#newer", as: "newer_pages"

    resources :chronicles
    resources :locations
    resources :members
    resources :memories
    resources :pictures
    resources :thoughts
    resources :weblinks

    get "/content_visibility/:id", to: "content_visibility#edit"
    get "/content_visibility/:id/edit", to: "content_visibility#edit", as: "edit_content_visibility"
    patch "/content_visibility/:id", to: "content_visibility#update", as: "content_visibility"

    get "new_search", to: "searches#new", as: "new_search"
    post "search", to: "searches#create", as: "search"
  end

  resources :switch_current_teams, only: %i[index show create destroy]

  # Login Controller
  resources :logins, only: %i[index destroy], as: :login_records
  # Registration Controller (public signup funnel; see also EmailVerifications below)
  get "register", to: "registrations#new", as: :new_registration
  post "register", to: "registrations#create", as: :registration
  # Session Controller
  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"

  namespace :admin, module: "admins", constraints: ->(request) { AdminConstraint.matches?(request) } do
    get "", to: "pages#show", as: "home"
    resources :chronicles
    resources :locations
    resources :members
    resources :memories # TODO: add views
    resources :pictures
    resources :teams
    resources :users
    resources :thoughts
    resources :weblinks
    get "record_events", to: "record_events#index", as: :record_events

    # NOTE: we setup Blazer::BaseController to inherit from our AdminController to only give admins access
    mount Blazer::Engine, at: "/blazer"

    # NOTE: we setup MissionControl to inherit from our AdminController to only give admins access
    mount MissionControl::Jobs::Engine, at: "/jobs"
  end

  # catch all unknown routes to NOT throw a FATAL ActionController::RoutingError
  match "*path", to: "application#error_404", via: :all,
    constraints: ->(request) { !request.path_parameters[:path].start_with?("rails/") }
end
