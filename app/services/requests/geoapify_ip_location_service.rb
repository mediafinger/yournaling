# NOTE: Use the module "Requests" for all services that make requests to external API endpoints
#
module Requests
  class GeoapifyIpLocationService
    class << self
      def call(ip_address:)
        endpoint = "v1/ipinfo"
        params = { ip: ip_address, apiKey: AppConf.geoapify_api_key }

        response = connection.get(endpoint, params:, headers:)
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

      def connection
        @connection ||= ::ChimeraHttpClient::Connection.new(
          base_url: AppConf.geoapify_api_url,
          user_agent: "#{AppConf.yournaling_name} (#{AppConf.yournaling_version})",
          logger: Rails.logger
        )
      end

      def headers
        {
          "Content-Type" => "application/json",
        }
      end
    end
  end
end
