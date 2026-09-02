# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Read and set Ruby version
ruby File.read(".ruby-version").strip.delete_prefix("ruby-")

gem "rails", "~> 8.1.3"

gem "action_policy", "~> 0.6" # Authorization solution based on pundit
gem "active_storage_validations" # to validate the content type and size of a file (add ruby-vips for dimensions)
gem "ahoy_matey", "~> 5.2" # Use ahoy for analytics
gem "bcrypt", "~> 3.1" # Use bcrypt for secure password hashing
gem "blazer", "~> 3.1" # Run SQL queries from the browser and display ahoy analytics in tables and graphs
gem "bootsnap", require: false
gem "chimera_http_client", "~> 1.6" # HTTP client based on Typhoeus / lib_curl
gem "countries", "~> 8.1" # Lists of countries, their ISO codes, emoji flags and more
gem "csv", require: false
gem "device_detector", "~> 1.1"
gem "dry-validation", "~> 1.10" # Use dry-validation for validations [https://dry-rb.org/gems/dry-validation]
# gem "exifr", "~> 1.3" # Read EXIF metadata from JPEG images
gem "geocoder" # (reverse) geocode addresses and GPS coordinates
gem "image_processing", "~> 2.0" # Use image_processing for image resizing in ActiveStorage variants
gem "importmap-rails", "~> 2.0" # Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
# gem "logstasher" # better formatted JSON logs for Logstash
gem "mission_control-jobs", "~> 1.0" # dashboard for SolidQueue jobs
gem "pagy", "~> 43.0" # fast and lightweight pagination solution
gem "pg", "~> 1.1"
gem "pg_search", "~> 2.3" # Use pg_search for full-text search in PostgreSQL
gem "positioning", "~> 0.4"
gem "propshaft" # The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "puma", "~> 8.0"
# gem "pundit", "~> 2.2" # Authorize actions by admin role
gem "rack-requestid", "~> 0.2" # always set a request_id with this middleware
gem "rack-timeout", "~> 0.6", require: "rack/timeout/base" # set a custom timeout in the middleware
gem "ruby-vips" # Use ruby-vips for image processing with ActiveStorage, requires the vips library
gem "scenic", "~> 1.9" # Versioned DB views that dump correctly into schema.rb
gem "slim-rails", "~> 4.0", require: ["slim", "slim/smart"] # Use slim 5.2 for HTML templates
gem "solid_cable", "~> 4.0"
gem "solid_cache", "~> 1.0"
gem "solid_queue", "~> 1.0"
gem "stimulus-rails" # Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "turbo-rails" # Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "view_component" # Use view_component for reusable view components [https://viewcomponent.org]

group :development do
  # gem "rails-erd"
  gem "fix-db-schema-conflicts" # to keep the schema.rb file sorted alphabetically without strong_migrations
  gem "letter_opener_web", "~> 3.0"
  gem "listen", "~> 3.9" # evented file watcher — Propshaft dev perf + Lookbook CSS auto-reload
  gem "lookbook", "~> 2.3" # component workbench (ViewComponent previews) at /lookbook
  gem "web-console"
end

group :development, :test do
  gem "active_record_doctor", "~> 2.0", require: false
  gem "amazing_print", "~> 2.0"
  gem "archspec"
  gem "brakeman", require: false
  gem "bundler-audit", "~> 0.9"
  gem "capybara", "~> 3.19"
  gem "factory_bot-awesome_linter", "~> 1.0"
  gem "factory_bot_rails", "~> 6.2"
  gem "faker", "~> 3.2"
  gem "kamal"
  gem "parallel"
  gem "rspec-rails", "~> 8.0"
  gem "rubocop-capybara", "~> 3.0"
  gem "rubocop-factory_bot", "~> 2.26"
  gem "rubocop-faker", "~> 1.1"
  gem "rubocop-performance", "~> 1.12"
  gem "rubocop-rails", "~> 2.21"
  gem "rubocop-rake", "~> 0.6"
  gem "rubocop-rspec", "~> 3.0"
  gem "rubocop-rspec_rails", "~> 2.30"
  gem "ruby-lsp"
  gem "ruby-lsp-rails", require: false
  gem "ruby-lsp-rspec", require: false
  gem "slim_lint"
end

group :test do
  gem "parallel_tests"
  gem "selenium-webdriver", "~> 4.14"
  gem "webmock", "~> 3.14"
end
