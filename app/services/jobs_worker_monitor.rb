# frozen_string_literal: true

# Answers one question for development-time diagnostics: is a Solid Queue worker
# actually running and claiming jobs right now?
#
# The app is regularly booted with `bin/rails server` instead of `bin/dev`, which
# skips the `jobs:` process from `Procfile.dev`. Jobs then pile up in the queue,
# silently. `JoblessBannerComponent` uses this to warn the developer.
class JobsWorkerMonitor
  class << self
    # True when at least one Solid Queue worker has sent a heartbeat within the
    # liveness threshold.
    #
    # Returns true ("assume fine, stay quiet") when the queue tables are missing
    # or unreadable — we only want to nag about a genuinely idle queue, not about
    # a half-configured one (e.g. before `db:prepare`).
    def worker_running?
      SolidQueue::Process
        .where(kind: "Worker")
        .exists?(last_heartbeat_at: SolidQueue.process_alive_threshold.ago..)
    rescue StandardError
      true
    end
  end
end
