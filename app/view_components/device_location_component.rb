class DeviceLocationComponent < ApplicationComponent
  erb_template <<-ERB
    <%= @infos.compact.join(" ") %>
  ERB

  def initialize(ip_address:)
    @ip_address = ip_address
  end

  def before_render
    @infos = Requests::GeoapifyIpLocationService.call(ip_address: @ip_address)
  end
end
