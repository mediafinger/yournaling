# frozen_string_literal: true

# Suppress upstream constant redefinition warnings across subprocesses on Ruby 4.0+
# NOTE
#   This does also suppress deprecation and other warnings, therefore it should probably be
#   conditional, to ensure none of such are thrown.
ENV["RUBYOPT"] = ["-W0", ENV["RUBYOPT"]].compact.join(" ").strip

require_relative "config/application"

Rails.application.load_tasks

if %w[development test].include? Rails.env
  require "active_record_doctor"
  require "active_record_doctor/rake/task"
  ENV["PARALLEL_TEST_RAKE_EXECUTABLE"] ||= File.exist?("bin/mcp_rake") ? "bin/mcp_rake" : "bundle exec rake"
  require "bundler/audit/task"
  require "parallel_tests/tasks"
  require "rspec/core/rake_task"
  require "rubocop/rake_task"
  require "slim_lint/rake_task"

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

  # setup task rspec to run in parallel
  desc "Run RSpec test suite in parallel"
  task rspec: :environment do
    ENV["PARALLEL_TEST_PROCESSORS"] ||= "4"
    sh "bundle exec parallel_rspec -n 4 spec/"

    # t.exclude_pattern = "**/{requests,controllers}/**/*_spec.rb" # example, here how to skip integration specs
    # t.exclude_pattern = "**/{views}/**/*_spec.rb" if ENV["CI"].to_s == "true"
    # t.exclude_pattern = "**/{system}/**/*_spec.rb"
  end

  desc "Check clean Architecture with archspec"
  task archspec: :environment do
    sh "bundle exec archspec check"
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

  RuboCop::RakeTask.new do |task|
    task.requires << "rubocop-rails"
  end

  SlimLint::RakeTask.new

  desc "Lint + format-check the CSS design system (stylelint + prettier)"
  task :css do # rubocop:disable Rails/RakeEnvironment -- pure Node toolchain, no Rails boot needed
    sh "bin/lint_css"
  end

  desc "Run test suite"
  task ci: %w[zeitwerk:check rubocop slim_lint css factory_bot:awesome_lint db:doctor rspec archspec
              bundle:audit:update bundle:audit]

  task default: :ci
end
