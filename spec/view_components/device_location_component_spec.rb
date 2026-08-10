# frozen_string_literal: true

require "rails_helper"

RSpec.describe DeviceLocationComponent, type: :component do
  it "renders geolocated city, flag, and country name" do
    allow(Requests::GeoapifyIpLocationService).to receive(:call)
      .with(ip_address: "185.15.59.224")
      .and_return(["Granada", "🇪🇸", "Spain"])

    rendered = render_inline(described_class.new(ip_address: "185.15.59.224"))

    expect(rendered.to_html).to include("Granada 🇪🇸 Spain")
  end
end
