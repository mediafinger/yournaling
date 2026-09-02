# frozen_string_literal: true

require "active_support/core_ext/integer/time"

# Staging mirrors production almost entirely: it is a production(-like)
# environment (see AppConf.production_env), so every setting keyed on that flag
# — required ENV vars, S3 storage, STDOUT logging, SSL — already applies here.
#
# The one architectural difference is topology: staging runs the whole stack
# (Puma, Solid Queue, and all four PostgreSQL databases) on a single server,
# whereas production scales web/job processes horizontally against dedicated
# database servers. That difference is expressed through ENV / AppConf on the
# server (WEB_CONCURRENCY, JOB_CONCURRENCY, SOLID_QUEUE_IN_PUMA, the *_DB_URLs),
# not in this file.
require_relative "production"

Rails.application.configure do
  # Settings specified here take precedence over production.rb and application.rb.

  # Staging is reached through a throwaway hostname; allow it explicitly and
  # keep the health check reachable without host authorization.
  config.hosts << AppConf.yournaling_host if AppConf.yournaling_host.present?
  config.host_authorization = { exclude: ->(request) { request.path.in?(["/up", "/alive"]) } }
end
