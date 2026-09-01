# frozen_string_literal: true

# One-line human summary of a device parsed from a User-Agent string.
class DeviceComponent < ApplicationComponent
  attr_reader :infos

  def initialize(user_agent:)
    device = DeviceDetector.new(user_agent)
    @infos = [
      device.device_name,
      device.device_type&.titleize,
      device.os_name,
      device.name,
    ].compact
  end
end
