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

    desc "Security gates (brakeman, bundler-audit, importmap audit)"
    task :security do # rubocop:disable Rails/RakeEnvironment -- gates shell out; no Rails boot needed
      exit(1) unless CIGate.run_group("security", {
        "brakeman"        => %w[bundle exec brakeman --quiet --no-pager --no-progress --exit-on-warn],
        "bundler_audit"   => %w[bin/bundler-audit check --update],
        "importmap_audit" => %w[bin/importmap audit],
      })
    end

    desc "Integrity gates that boot the app (zeitwerk, db:doctor, factory lint, archspec)"
    task :checks do # rubocop:disable Rails/RakeEnvironment -- each gate is its own `bundle exec rake` subprocess
      exit(1) unless CIGate.run_group("checks", {
        "zeitwerk"     => %w[bundle exec rake zeitwerk:check],
        "db_doctor"    => %w[bundle exec rake db:doctor],
        "factory_lint" => %w[bundle exec rake factory_bot:awesome_lint],
        "archspec"     => %w[bundle exec archspec check],
      })
    end
  end

  # Alias of the top-level `rspec` task (defined in the Rakefile), named for
  # symmetry with the other steps. Declared here at top level so the `:rspec`
  # prerequisite resolves to `rake rspec`, not to itself.
  desc "Run the RSpec suite in parallel (alias of `rake rspec`)"
  task "ci:rspec" => "rspec"

  desc "Run the full quality-gate suite (lint -> security -> checks -> rspec, fail-fast)"
  task ci: %w[ci:lint ci:security ci:checks ci:rspec]

  task default: :ci
end
