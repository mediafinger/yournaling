# frozen_string_literal: true

# `rake ci` — the quality-gate suite.
#
# See README_RAKE_CI.markdown for the full reference. The wiring lives here
# rather than in the Rakefile so it has room to grow into namespaced steps
# (ci:lint / ci:security / ci:checks / ci:rspec).
#
# Development / test only: production bundles omit the tooling gems.

if %w[development test].include?(Rails.env)
  desc "Run the full quality-gate suite"
  task ci: %w[zeitwerk:check rubocop slim_lint css factory_bot:awesome_lint db:doctor rspec archspec
              bundle:audit:update bundle:audit]

  task default: :ci
end
