class DeviceComponent < ApplicationComponent
  slim_template <<~SLIM
    ul
      @infos.each do |info|
        li
          = info
  SLIM

  def initialize(user_agent:)
    device = DeviceDetector.new(user_agent)
    @infos = [
      device.device_name,
      device.device_type.titleize,
      device.os_name,
      device.name,
    ].compact
  end
end
