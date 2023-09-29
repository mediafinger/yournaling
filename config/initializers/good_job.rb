# see: https://github.com/bensheldon/good_job#configuration-options

Rails.application.configure do
  config.good_job = {
    preserve_job_records: true,
    retry_on_unhandled_error: false,
    # on_thread_error: -> (exception) { Sentry.capture_exception(exception) },

    # excution_mode documentation:
    # :inline executes jobs immediately in whatever process queued them (usually the web server process).
    #   This should only be used in test and development environments.
    # :external causes the adapter to enqueue jobs, but not execute them.
    #   When using this option (the default for production environments), you’ll need to use the command-line tool
    #   to actually execute your jobs.
    # :async (or :async_server) executes jobs in separate threads within the Rails web server process
    #   (bundle exec rails server). It can be more economical for small workloads because you don’t need a separate machine
    #   or environment for running your jobs, but if your web server is under heavy load or your jobs require a lot of
    #   resources, you should choose :external instead.
    #   When not in the Rails web server, jobs will execute in :external mode to ensure jobs are not executed within
    #   rails console, rails db:migrate, rails assets:prepare, etc.
    #
    execution_mode: :async,

    queues: "*",
    max_threads: 5,
    poll_interval: 30,
    shutdown_timeout: 25,
    # enable_cron: true,
    # cron: {
    #   example: {
    #     cron: "0 * * * *",
    #     class: "ExampleJob"
    #   },
    # },
  }
end
