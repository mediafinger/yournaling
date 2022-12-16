source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.1.2"

gem "rails", "7.0.4"

gem "bootsnap", require: false
gem "dry-validation", "~> 1.10" # Use dry-validation for validations [https://dry-rb.org/gems/dry-validation]
gem "importmap-rails" # Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "pg", "~> 1.1"
gem "puma", "~> 5.0"
gem "redis", "~> 4.0" # Use Redis for Action Cable / Turbo-Reflex
gem "sprockets-rails" # The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem "stimulus-rails" # Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "tailwindcss-rails" # Use Tailwind CSS [https://github.com/rails/tailwindcss-rails]
gem "turbo-rails" # Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]

group :development do
  gem "web-console"
end

group :development, :test do
  gem "amazing_print", "~> 1.4"
  gem "bundler-audit", "~> 0.9"
  gem "factory_bot_rails", "~> 6.2"
  gem "faker", "~> 2.19"
  gem "rspec-rails", "~> 6.0"
end

group :test do
  gem "webmock", "~> 3.14"
end
