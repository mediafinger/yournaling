# frozen_string_literal: true

# Development-only warning bubble, shown when the app runs without a Solid Queue
# worker — typically because it was started with `bin/rails server` instead of
# `bin/dev`. Background jobs are then enqueued but never executed.
#
# Rendered from every layout right after the flash region. `render?` keeps it out
# of test and production, and out of the way once a worker is up.
class JoblessBannerComponent < ViewComponent::Base
  def render?
    Rails.env.development? && !JobsWorkerMonitor.worker_running?
  end
end
