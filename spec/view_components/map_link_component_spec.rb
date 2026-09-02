# frozen_string_literal: true

require "rails_helper"

RSpec.describe MapLinkComponent, type: :component do
  let(:team) { FactoryBot.create(:team) }
  let(:location) do
    FactoryBot.create(
      :location,
      team: team,
      lat: 36.7491,
      long: -2.2425,
      address: "Cabo de Gata, Spain"
    )
  end

  it "renders a static map image linked to Google Maps coordinates" do
    rendered = render_inline(described_class.new(location: location, width: 400, height: 300))

    expect(rendered.to_html).to have_css("a.yui-media-link")
    expect(rendered.to_html).to have_link(href: location.gmaps_coordinates_url)

    link = rendered.css("a").first
    expect(link[:target]).to eq("_blank")
    expect(link[:rel]).to eq("noopener")

    img = rendered.css("img").first
    expect(img[:alt]).to eq("Cabo de Gata, Spain")
    expect(img[:width]).to eq("400")
    expect(img[:height]).to eq("300")
    expect(img[:src]).to include("maps.geoapify.com/v1/staticmap")
  end
end
