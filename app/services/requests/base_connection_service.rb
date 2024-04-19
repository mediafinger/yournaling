# NOTE: Use the module "Requests" for all services that make requests to external API endpoints
#   And let all services inherit from this BaseConnectionService.
#   If they are are no fit (e.g. when they use a specific API client), then group them under another directory / module.
#
module Requests
  class BaseConnectionService
    class << self
      private

      def connection
        @connection ||= ::ChimeraHttpClient::Connection.new(base_url:, logger:, user_agent:) # REFACTOR: add cache:
      end

      def queue_connection
        @queue_connection ||= ChimeraHttpClient::Queue.new(base_url:, logger:, user_agent:) # REFACTOR: add cache:
      end

      def base_url
        raise NotImplementedError # implement this method in the inheriting class
      end

      def headers
        {
          "Content-Type" => "application/json",
        }
      end

      def logger
        Ethon.logger = Logger.new(nil) # disable ETHON log messages, as we use a custom logger
        @logger ||= Rails.logger
      end

      def user_agent
        "#{AppConf.yournaling_name} (#{AppConf.yournaling_version})"
      end

      # REFACTOR: activate cache usage to save API requests
      # run `rails dev:cache` to toggle cache usage in development mode
      def cache(seconds = 0)
        @cache ||= seconds.zero? ? nil : Typhoeus::Cache::Rails.new(Rails.cache, default_ttl: seconds)
      end
    end
  end
end
