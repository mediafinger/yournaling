# frozen_string_literal: true

# One-line "City 🇨🇨 Country" from a geolocated IP address.
class DeviceLocationComponent < ApplicationComponent
  attr_reader :infos

  def initialize(ip_address:)
    @ip_address = ip_address
  end

  def before_render
    @infos = Requests::GeoapifyIpLocationService.call(ip_address: @ip_address)
  end
end
