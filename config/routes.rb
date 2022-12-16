Rails.application.routes.draw do
  root to: proc { [200, {}, [""]] } # TODO: render a real home page, not just a blank page

  # catch all unknown routes to NOT throw a FATAL ActionController::RoutingError
  match "*path", to: "application#error_404", via: :all,
    constraints: ->(request) { !request.path_parameters[:path].start_with?("rails/") }
end
