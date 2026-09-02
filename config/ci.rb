# frozen_string_literal: true

# Run using `bin/ci`. This mirrors `rake ci` (see README_RAKE_CI.markdown) —
# same four steps, same order, same fail-fast — with the Rails 8 CI runner's
# step framing and the optional GitHub sign-off hook below. GitHub Actions
# runs `bundle exec rake ci` directly; `bin/ci` is the local alternative.

CI.run do
  step "Setup", "bin/setup --skip-server"

  step "Lint", "bin/rake ci:lint"
  step "Security", "bin/rake ci:security"
  step "Checks", "bin/rake ci:checks"
  step "Tests", "bin/rake ci:rspec"

  # Optional: set a green GitHub commit status to unblock PR merge.
  # Requires the `gh` CLI and `gh extension install basecamp/gh-signoff`.
  # if success?
  #   step "Signoff: All systems go. Ready for merge and deploy.", "gh signoff"
  # else
  #   failure "Signoff: CI failed. Do not merge or deploy.", "Fix the issues and try again."
  # end
end
