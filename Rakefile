require_relative "config/application"

Rails.application.load_tasks

if %w(development test).include? Rails.env
  require "bundler/audit/task"
  require "rspec/core/rake_task"

  # setup task bundle:audit
  Bundler::Audit::Task.new

  # setup task rspec
  RSpec::Core::RakeTask.new(:rspec) do |t|
    # t.exclude_pattern = "**/{requests,blocknox}/**/*_spec.rb" # example, here how to skip integration specs
  end

  namespace :factory_bot do
    desc "Verify that all FactoryBot factories are valid"
    task lint: :environment do
      puts "Building all factories and traits to ensure they are valid"
      FactoryBot.lint traits: true, strategy: :build, verbose: true
    end
  end

  desc "Run test suite"
  task ci: %w(factory_bot:lint rspec bundle:audit)

  task default: :ci
end
