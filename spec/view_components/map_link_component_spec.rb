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

  context "when a Geoapify key is configured" do
    before { allow(AppConf).to receive(:geoapify_api_key).and_return("a-real-key") }

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

  context "without a usable Geoapify key (e.g. development)" do
    before { allow(AppConf).to receive(:geoapify_api_key).and_return("secret_key") }

    it "falls back to a plain Google Maps link and renders no broken image" do
      rendered = render_inline(described_class.new(location: location, width: 400, height: 300))

      expect(rendered.css("img")).to be_empty
      expect(rendered.to_html).to have_link("Open in Google Maps", href: location.gmaps_coordinates_url)
    end
  end

  it "renders nothing for a location without coordinates" do
    location.update_columns(lat: nil, long: nil)
    rendered = render_inline(described_class.new(location: location, width: 400, height: 300))

    expect(rendered.to_html).to be_blank
  end
end
