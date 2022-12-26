# Use Resque - the Redis Queue - as ActiveJob backend
Rails.application.config.active_job.queue_adapter = :resque
Rails.application.config.active_job.queue_name_prefix = "#{AppConf.yournaling_name}-#{AppConf.environment}"
