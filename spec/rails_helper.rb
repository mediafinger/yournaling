# This file is copied to spec/ when you run 'rails generate rspec:install'

ENV["RAILS_ENV"] ||= "test"

require_relative "../config/environment"

# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?

require "rspec/rails"
require "webmock/rspec"
WebMock.disable_net_connect!(allow_localhost: true)

require "capybara/rails"

require "spec_helper"

# configure Capybara for system specs
Capybara.server = :puma, { Silent: true } # To clean up your test output
# set default driver which is fast, but does not support JavaScript
Capybara.register_driver :rack_test do |app|
  Capybara::RackTest::Driver.new(app, headers: { "HTTP_USER_AGENT" => "Capybara" })
end

Dir[Rails.root.join("spec/support/**/*.rb")].sort.each { |f| require f }

# to use freeze_time and travel_to
include ActiveSupport::Testing::TimeHelpers

# Checks for pending migrations and applies them before tests are run.
# If you are not using ActiveRecord, you can remove these lines.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  # abort e.to_s.strip
  puts "******************** WARNING: Pending migrations: #{e.to_s.strip} *********************************"
end

FactoryBot::SyntaxRunner.class_eval do
  include ActionDispatch::TestProcess::FixtureFile # to test active_storage file uploads
end

RSpec.configure do |config|
  # To get the full backtrace of deprectations
  # config.raise_errors_for_deprecations!

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_paths = [ "#{Rails.root.join('spec/fixtures')}" ]

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # You can uncomment this line to turn off ActiveRecord support entirely.
  # config.use_active_record = false

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, type: :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")

  config.include Authentication, type: :controller
  config.include TeamScope, type: :controller
  config.include RequestContext, type: :controller

  config.include ActiveSupport::Testing::TimeHelpers
  config.include ViewComponent::TestHelpers, type: :component
  config.include ViewComponent::SystemTestHelpers, type: :component
  config.include Capybara::RSpecMatchers, type: :component
end
