uri = URI.parse(AppConf.redis_url)
Resque.redis = Redis.new(host: uri.host, port: uri.port, password: AppConf.redis_password)
