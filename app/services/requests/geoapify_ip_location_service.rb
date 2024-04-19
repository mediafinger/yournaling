module Requests
  class GeoapifyIpLocationService < BaseConnectionService
    class << self
      def call(ip_address:)
        endpoint = "v1/ipinfo"
        params = { ip: ip_address, apiKey: AppConf.geoapify_api_key }

        response = connection.get(endpoint, params:, headers:) # REFACTOR: to use queue_connection
        return [ip_address] unless response.success?

        location = [
          response.parsed_body.dig("city", "name"),
          response.parsed_body.dig("country", "flag"),
          response.parsed_body.dig("country", "name"),
        ].compact

        return [ip_address] if location.blank?

        location
      end

      private

      def base_url
        AppConf.geoapify_api_url
      end
    end
  end
end
