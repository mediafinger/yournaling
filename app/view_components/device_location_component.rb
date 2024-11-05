class DeviceLocationComponent < ApplicationComponent
  slim_template <<~SLIM
    = @infos.compact.join(" ")
  SLIM

  def initialize(ip_address:)
    @ip_address = ip_address
  end

  def before_render
    @infos = Requests::GeoapifyIpLocationService.call(ip_address: @ip_address)
  end
end
