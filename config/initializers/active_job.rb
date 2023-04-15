# Use Async - the default - as ActiveJob backend
Rails.application.config.active_job.queue_adapter = :async
Rails.application.config.active_job.queue_name_prefix = "#{AppConf.yournaling_name}-#{AppConf.environment}"
