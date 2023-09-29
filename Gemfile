source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Read and set Ruby version
ruby File.read(".ruby-version").strip.delete_prefix("ruby-")

gem "rails", "7.1.0.rc1"

# gem "action_policy", "~> 0.6" # Authorization solution based on pundit
gem "bcrypt", "~> 3.1" # Use bcrypt for secure password hashing
gem "bootsnap", require: false
# gem "chimera_http_client", "~> 1.3" # HTTP client based on Typhoeus / lib_curl
gem "dry-validation", "~> 1.10" # Use dry-validation for validations [https://dry-rb.org/gems/dry-validation]
# gem "exifr", "~> 1.3" # Read EXIF metadata from JPEG images
gem "image_processing", "~> 1.12" # Use image_processing for image resizing in ActiveStorage variants
gem "importmap-rails" # Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
# gem "logstasher" # better formatted JSON logs for Logstash
# gem "pagy", "~> 5.10" # fast and lightweight pagination solution # TODO: require "pagy/extras/navs"
gem "pg", "~> 1.1"
gem "puma", "~> 6.3"
# gem "pundit", "~> 2.2" # Authorize actions by admin role
gem "rack-requestid", "~> 0.2" # always set a request_id with this middleware
gem "rack-timeout", "~> 0.6", require: "rack/timeout/base" # set a custom timeout in the middleware
gem "redis", "~> 5.0" # Use Redis for Action Cable / Turbo-Reflex
gem "resque", "~> 2.4" # Use Resque for background jobs
gem "sprockets-rails" # The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem "stimulus-rails" # Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "turbo-rails" # Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]

group :development do
  gem "web-console"
end

group :development, :test do
  gem "active_record_doctor", "~> 1.10", require: false
  gem "amazing_print", "~> 1.4"
  gem "bundler-audit", "~> 0.9"
  gem "factory_bot-awesome_linter", "~> 1.0"
  gem "factory_bot_rails", "~> 6.2"
  gem "faker", "~> 3.2"
  gem "rspec-rails", "~> 6.0"
  gem "rubocop-rails", "~> 2.21", require: false
end

group :test do
  gem "webmock", "~> 3.14"
end
