# see: https://github.com/bensheldon/good_job#configuration-options

Rails.application.configure do
  config.active_job.queue_adapter = :good_job
  config.active_job.queue_name_prefix = "yournaling_#{AppConf.environment}"

  config.good_job = {
    dashboard_default_locale: :en,
    logger: Rails.logger,
    preserve_job_records: true,
    retry_on_unhandled_error: false,
    # on_thread_error: ->(exception) { Sentry.capture_exception(exception) },

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
    max_threads: AppConf.good_job_max_threads,
    poll_interval: 30,
    shutdown_timeout: 25,
    # enable_cron: true, # or e.g. ENV["DYNO"] == "worker.1"
    # cron: {
    #   example_name: {cron: "1,16,31,46 * * * *",
    #     class: "...Job",
    #       args: ["some specific message"],
    #       set: { priority: 10 },
    #       description: "blubber"
    #     },
    # },
  }
end

__END__

How to calculate how many DB Connections are necessary:

If you're using all default values (e.g. GOOD_JOB_QUEUES=* GOOD_JOB_MAX_THREADS=5)
then this formula there should be the correct one:

* One pool of 5 executor threads,
  pulling job from default and mailers,
  each with their own database connection
  = 5 connections.

* One LISTEN/NOTIFY connection
  = 1 connections.

* Goodjob Cron enqueuer
  = 2 connections.

* In total GoodJob needs
  = 8 db connections

* Plus the Puma web threads
  = 5 db connections

= 13 db connections should be in the pool (minimum, probably add a few for other processes, like running a console)
