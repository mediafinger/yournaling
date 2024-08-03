source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Read and set Ruby version
ruby File.read(".ruby-version").strip.delete_prefix("ruby-")

gem "rails", "~> 7.2.1"

gem "action_policy", "~> 0.6" # Authorization solution based on pundit
gem "active_storage_validations" # to validate the content type and size of a file (add ruby-vips for dimensions)
gem "bcrypt", "~> 3.1" # Use bcrypt for secure password hashing
gem "bootsnap", require: false
gem "chimera_http_client", "~> 1.6" # HTTP client based on Typhoeus / lib_curl
gem "countries", "~> 6.0" # Lists of countries, their ISO codes, emoji flags and more
gem "csv", require: false
gem "device_detector", "~> 1.1"
gem "dry-validation", "~> 1.10" # Use dry-validation for validations [https://dry-rb.org/gems/dry-validation]
# gem "exifr", "~> 1.3" # Read EXIF metadata from JPEG images
gem "geocoder" # (reverse) geocode addresses and GPS coordinates
gem "good_job" # Use good_job as active_job backend for a simpler setup with queueing in postgres
gem "image_processing", "~> 1.12" # Use image_processing for image resizing in ActiveStorage variants
gem "importmap-rails", "~> 2.0" # Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
# gem "logstasher" # better formatted JSON logs for Logstash
# gem "pagy", "~> 5.10" # fast and lightweight pagination solution # TODO: require "pagy/extras/navs"
gem "pg", "~> 1.1"
gem "pg_search", "~> 2.3" # Use pg_search for full-text search in PostgreSQL
gem "puma", "~> 6.3"
# gem "pundit", "~> 2.2" # Authorize actions by admin role
gem "rack-requestid", "~> 0.2" # always set a request_id with this middleware
gem "rack-timeout", "~> 0.6", require: "rack/timeout/base" # set a custom timeout in the middleware
gem "redis", "~> 5.0" # Use Redis for Action Cable / Turbo-Reflex
gem "ruby-vips" # Use ruby-vips for image processing with ActiveStorage, requires the vips library
gem "sprockets-rails" # The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem "stimulus-rails" # Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "strong_migrations", "~> 1.6" # Catch unsafe migrations in development
gem "turbo-rails" # Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "view_component" # Use view_component for reusable view components [https://viewcomponent.org]

group :development do
  # gem "rails-erd"
  gem "web-console"
end

group :development, :test do
  gem "active_record_doctor", "~> 1.10", require: false
  gem "amazing_print", "~> 1.4"
  gem "bundler-audit", "~> 0.9"
  gem "capybara", "~> 3.19" # for headless browser tests
  gem "factory_bot-awesome_linter", "~> 1.0"
  gem "factory_bot_rails", "~> 6.2"
  gem "faker", "~> 3.2"
  gem "rspec-rails", "~> 6.0"
  gem "rubocop-capybara", "~> 2.19", require: false
  gem "rubocop-faker", "~> 1.1", require: false
  gem "rubocop-performance", "~> 1.12", require: false
  gem "rubocop-rails", "~> 2.21", require: false
  gem "rubocop-rake", "~> 0.6", require: false
  gem "rubocop-rspec", "~> 2.6", require: false
end

group :test do
  gem "selenium-webdriver", "~> 4.14" # for headless browser tests
  gem "webmock", "~> 3.14"
end
