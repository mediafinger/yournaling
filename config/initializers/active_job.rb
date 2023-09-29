# Use GoodJob - the Postgres queue - as ActiveJob backend
Rails.application.config.active_job.queue_adapter = :good_job
Rails.application.config.active_job.queue_name_prefix = "#{AppConf.yournaling_name}-#{AppConf.environment}"
