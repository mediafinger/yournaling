require_relative "config/application"

Rails.application.load_tasks

if %w(development test).include? Rails.env
  require "active_record_doctor"
  require "active_record_doctor/rake/task"
  require "bundler/audit/task"
  require "rspec/core/rake_task"

  # setup task bundle:audit
  Bundler::Audit::Task.new

  # setup task active_record_doctor
  ActiveRecordDoctor::Rake::Task.new do |task|
    # Add project-specific Rake dependencies that should be run before running active_record_doctor.
    task.deps = [:environment]

    # A path to your active_record_doctor configuration file.
    task.config_path = Rails.root.join(".active_record_doctor")

    # A Proc called right before running detectors that should ensure your Active
    # Record models are preloaded and a database connection is ready.
    task.setup = -> { Rails.application.eager_load! }
  end

  # setup db:doctor, using the rake task defined above
  # running on the development DB to not interfere other tasks on the test DB on GitHub Actions CI
  namespace :db do
    desc "Check the integrity of the database schema"
    task doctor: :environment do
      puts "DB Doctor is running..."
      # Rake::Task["active_record_doctor"].invoke
      puts `RAILS_ENV=development bundle exec rake active_record_doctor` # to make it work on GitHub Actions CI
      check_status = $?.exitstatus # rubocop:disable Style/SpecialGlobalVars
      exit check_status unless check_status.zero?
    end
  end

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

    # better linter output
    desc "Verify that all FactoryBot factories are valid"
    task awesome_lint: :environment do
      puts "Building all factories and traits to ensure they are valid"
      abort unless FactoryBot::AwesomeLinter.lint! traits: true, strategy: :build
    end
  end

  desc "Run test suite"
  task ci: %w(factory_bot:awesome_lint db:doctor rspec bundle:audit)

  task default: :ci
end
