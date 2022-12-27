require_relative "boot"

# Read ENV variables and make AppConf settings available
require_relative "app_conf"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
# require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

require "rack/requestid"

require_relative File.expand_path("../app/errors/errors_middleware", __dir__)

module Yournaling
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Middleware configuration:

    # Rack::RequestID ensures that every request has HTTP_X_REQUEST_ID set
    # It needs to reside in the callchain before ActionDispatch::RequestId
    # ActionDispatch::RequestId creates a request_id or uses HTTP_X_REQUEST_ID
    # but it will not change the request header (only sets the response header)
    config.middleware.insert_before(
      ActionDispatch::RequestId,
      ::Rack::RequestID, include_response_header: true, overwrite: false
    )

    # # set rack-timeout / test in production to not set it to low
    config.middleware.insert_after(
      ActionDispatch::RequestId,
      Rack::Timeout, service_timeout: AppConf.rack_timeout # seconds
    )
    Rack::Timeout::Logger.disable # we only log the errors, not the verbose status messages

    # handle all thrown exceptions with proper logging and responding with JSONAPI errors or nice HTML pages / flashes
    unless AppConf.is?(:debug, true)
      config.middleware.insert_after(
        ActionDispatch::PermissionsPolicy::Middleware,
        ::ErrorsMiddleware
      )
    end

    # These setting are used when running `rails generate ...`
    #
    config.generators do |g|
      g.orm :active_record, primary_key_type: :uuid

      g.helper false
      # g.javascripts true # StimulusJS
      # g.stylesheets true
      # g.template_engine :erb

      g.test_framework :rspec, fixture: false
      g.controller_specs false
      g.factory_bot suffix: "factory"
      g.helper_specs false
      g.routing_specs false
      g.system_tests true
      g.view_specs true
    end
  end
end
