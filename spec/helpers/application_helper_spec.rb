# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#active_path?" do
    it "returns true when current request path begins with given path" do
      allow(helper).to receive_message_chain(:request, :path).and_return("/current_team/locations/new") # rubocop:disable RSpec/MessageChain
      expect(helper.active_path?("/current_team")).to be true
      expect(helper.active_path?("/current_team/locations")).to be true
    end

    it "returns false when current request path does not begin with given path" do
      allow(helper).to receive_message_chain(:request, :path).and_return("/teams/123") # rubocop:disable RSpec/MessageChain
      expect(helper.active_path?("/admin")).to be false
    end
  end

  describe "#render_svg" do
    let(:fake_asset) { instance_double(Propshaft::Asset, content: +"<svg viewBox='0 0 24 24'></svg>") }

    it "renders SVG with class and style options" do
      allow(Rails.application.assets.load_path).to receive(:find).with("logo.svg").and_return(fake_asset)

      rendered = helper.render_svg("logo", class: "brand-logo", style: "width: 48px;")

      expect(rendered).to include("class=\"brand-logo\"")
      expect(rendered).to include("style=\"width: 48px;\"")
      expect(rendered).to include("<svg")
    end

    it "raises ArgumentError when svg file does not exist" do
      allow(Rails.application.assets.load_path).to receive(:find).with("missing.svg").and_return(nil)

      expect {
        helper.render_svg("missing")
      }.to raise_error(ArgumentError, /SVG image file does not exist: missing/)
    end
  end
end
