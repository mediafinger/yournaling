# Instead of using ENV variables in the code,
#   read them at startup and store them in this AppConf object.
# This allows to:
# - work with default values,
# - overwrite some values in a config/yournaling_conf.local.rb file,
# - compare values type agnostic with the `.is?` method,
# - ensure that typos in the variable names are detected at 'compile' time
# - see all keys of externaly set values in one file
# and this all comes without the help of another dependency.

# ENV can be set anywhere on your local machine or the server.
# For convenience, we use dotenv to set them.
# This allows to set default values in .env(.environment) files.
# And to overwrite some values in .env(.environment).local files, both locally and on production(-like) servers.

# EXAMPLES how to use this class:
#
# register :server_name
# register :api_base_url, default: "https://example.com/api"
# register :api_username, default: "development"
# register :api_password, default: "secret" # set default for development and test, not production
# register :db_name, required: true # ENV must be available
#
# This tries to read the ENV variables: SERVER_NAME, API_BASE_URL, API_USERNAME, API_PASSWORD, DB_NAME
#
# When an ENV is set, its value will be used.
# When an ENV is not set and a default is given, it will use the default.
# When an ENV is not set and no default is given, it will be nil.
# When an ENV is not set but it is required, it will raise an error.
#
# Access the objects in the code from anywhere like this:
# AppConf.server_name / AppConf.api_base_url ...

class AppConf
  class << self
    # sets instance variable with given name and value
    def set(var_name, value)
      instance_variable_set(:"@#{var_name}", value)
    end

    # creates getter method that reads the instance variable with given name
    # sets value from ENV variable
    #   or `default` value
    # will raise a KeyError on boot when `required: true` but ENV variable not set
    def register(var_name, default: nil, prefix: nil, required: false)
      define_singleton_method(var_name) { instance_variable_get(:"@#{var_name}") }

      env_name = [prefix, var_name].compact.join("_").upcase
      value = required ? ENV.fetch(env_name) : ENV.fetch(env_name, default)

      set(var_name, value)
    end

    # to compare a setting vs a value and 'ignore' type, no more Boolean or Number mis-comparisons
    def is?(var_name, other_value)
      public_send(var_name.to_sym).to_s == other_value.to_s
    end

    def production_env
      is?(:environment, :production)
    end

    # rubocop:disable Style/RescueStandardError
    def env_and_version
      return [environment, `git rev-parse --short HEAD`.strip].compact.join("-") if production_env

      "#{environment}-#{`cat .git/HEAD`.split('/').last.strip}"
    rescue
      environment
    end
    # rubocop:enable Style/RescueStandardError
  end

  # keep this register on top of all other commands
  #
  register :environment, default: ENV["RAILS_ENV"] || "development"

  register :debug, default: false # start console/server/specs with DEBUG=true for more logs and longer timeout

  register :yournaling_host, default: "localhost", required: production_env
  register :yournaling_name, default: "yournaling"
  register :yournaling_port, default: 3008
  register :yournaling_version, default: env_and_version

  # Database setup
  register :yournaling_db_host, default: "localhost"
  register :yournaling_db_name, default: "yournaling", required: production_env
  register :yournaling_db_password, default: ""
  register :yournaling_db_port, default: 5432
  register :yournaling_db_timeout_seconds, default: 5, required: production_env
  register :yournaling_db_username, default: "postgres"
  register :yournaling_db_url,
    default: "postgres://#{yournaling_db_username}:#{yournaling_db_password}@" \
             "#{yournaling_db_host}:#{yournaling_db_port}/#{yournaling_db_name}",
    required: production_env

  # determines the size of the DB connection pool and the puma threads
  register :rails_max_threads, default: 6
  register :rails_min_threads, default: 2
  # determines the size of the DB connection pool and the puma threads
  register :web_concurrency, default: 1
  # used for the job queue workers
  register :job_concurrency, default: 1
  # Run the Solid Queue supervisor inside of Puma for single-server/service deployments
  register :solid_queue_in_puma, default: false
  # Specify the PID file. Defaults to tmp/pids/server.pid in development.
  register :pidfile, default: production_env ? nil : "tmp/pids/server.pid"
  # on production we should use a SecureRandom.hex(64) String with 128 characters
  register :rails_secret_key_base, required: production_env, default: "foofoobar123456"
  # Enable static file serving from the `/public` folder (turn off if using a CDN or NGINX/Apache for it).
  register :rails_serve_static_files, default: true # Rails 7.1 default
  # Error pages, have only an effect in development
  register :display_rails_error_page, default: is?(:debug, true)
  # include full stacktrace in error messages
  register :full_backtrace, default: is?(:debug, true)
  # Adds (lograge) Rails logs to the output, only use in development when needed
  register :display_rails_logs, default: is?(:debug, true)

  # Logs & Logging
  register :log_level, default: if is?(:debug, true)
                                  :debug
                                elsif is?(:environment, :development) # rubocop:disable Lint/DuplicateBranch
                                  :debug
                                elsif is?(:environment, :test)
                                  :warn
                                else
                                  ENV.fetch("RAILS_LOG_LEVEL", :info)
                                end
  register :log_target, default: production_env ? $stdout : "log/#{environment}.log"

  # rack-timeout in seconds
  register :rack_timeout, default: is?(:debug, true) ? 300 : 10 # seconds

  # external service configuration

  # Amazon S3
  register :amazon_s3_access_key_id, default: "access_key_id", required: production_env
  register :amazon_s3_secret_access_key, default: "secret_access_key", required: production_env
  register :amazon_s3_bucket_name, default: "yournaling", required: production_env

  # Geoapify API
  register :geoapify_api_key, default: "secret_key", required: production_env
  register :geoapify_api_url, default: "https://api.geoapify.com", required: production_env

  # Don't add secrets as 'default' values in this file!
  #
  # Either set ENV vars for secrets on the server
  #   or for local usage add them to the following file, which is in .gitignore:
  #
  load "config/app_conf.local.rb" if !is?(:environment, :test) && File.exist?("config/app_conf.local.rb")
  #
  # inside use this syntax:
  #   AppConf.set :password, "secret"
end
