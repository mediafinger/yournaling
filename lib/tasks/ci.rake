# frozen_string_literal: true

# `rake ci` — the quality-gate suite.
#
# See README_RAKE_CI.markdown for the full reference. Each `ci:<step>` runs its
# gates in parallel (buffered output, all failures reported); the steps
# themselves run serially and fail fast via the `ci` task's prerequisites.
#
# Development / test only: production bundles omit the tooling gems.

if %w[development test].include?(Rails.env)
  require_relative "support/ci_gate"

  namespace :ci do
    desc "Style & format gates (rubocop, slim-lint, css, actionlint)"
    task :lint do # rubocop:disable Rails/RakeEnvironment -- gates shell out; no Rails boot needed
      exit(1) unless CIGate.run_group("lint", {
        "rubocop"    => %w[bundle exec rubocop --no-server],
        "slim_lint"  => %w[bundle exec slim-lint app],
        "css"        => %w[bin/css_lint],
        "actionlint" => %w[bin/actionlint],
      })
    end
  end

  desc "Run the full quality-gate suite"
  task ci: %w[zeitwerk:check rubocop slim_lint css factory_bot:awesome_lint db:doctor rspec archspec
              bundle:audit:update bundle:audit]

  task default: :ci
end
