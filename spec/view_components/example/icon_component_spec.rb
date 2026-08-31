# frozen_string_literal: true

require "rails_helper"

RSpec.describe Example::IconComponent, type: :component do
  it "renders an inline svg for a known name" do
    rendered = render_inline(described_class.new("calendar"))

    svg = rendered.css("svg.ex-icon").first
    expect(svg).to be_present
    expect(svg["viewBox"] || svg["viewbox"]).to eq("0 0 24 24")
    expect(svg.inner_html).to include("<path")
  end

  it "falls back to the sparkle glyph for an unknown name" do
    rendered = render_inline(described_class.new("does-not-exist"))

    expect(rendered.to_html).to eq(render_inline(described_class.new("sparkle")).to_html)
  end

  it "maps size to a modifier class" do
    rendered = render_inline(described_class.new("book", size: :lg))

    expect(rendered).to have_css("svg.ex-icon.ex-icon--lg")
  end

  describe "accessibility" do
    it "is aria-hidden and non-focusable when decorative (no label)" do
      rendered = render_inline(described_class.new("book"))

      expect(rendered).to have_css("svg[aria-hidden='true'][focusable='false']")
      expect(rendered).to have_no_css("svg title")
    end

    it "exposes a label and title when given one" do
      rendered = render_inline(described_class.new("map-pin", label: "Location"))

      expect(rendered).to have_css("svg[role='img'][aria-label='Location']")
      expect(rendered).to have_css("svg title", text: "Location", visible: :all)
    end
  end
end
