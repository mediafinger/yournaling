# frozen_string_literal: true

require "rails_helper"

RSpec.describe Yui::LinkComponent, type: :component do
  it "renders an anchor with the base class" do
    rendered = render_inline(described_class.new("Read on", href: "/x"))

    expect(rendered).to have_link("Read on", href: "/x", class: "yui-link")
  end

  it "adds a modifier class for non-default variants" do
    rendered = render_inline(described_class.new("Back", href: "#", variant: :muted))

    expect(rendered).to have_css("a.yui-link.yui-link--muted")
  end

  it "appends a nudging arrow for the standalone variant" do
    rendered = render_inline(described_class.new("More", href: "#", variant: :standalone))

    expect(rendered).to have_css("a.yui-link--standalone svg.yui-icon[aria-hidden='true']")
  end

  describe "external links" do
    let(:rendered) { render_inline(described_class.new("mediafinger.com", href: "https://mediafinger.com", external: true)) }

    it "opens in a new tab safely" do
      link = rendered.css("a").first
      expect(link[:target]).to eq("_blank")
      expect(link[:rel]).to eq("noopener noreferrer")
    end

    it "shows an outward arrow that is hidden from assistive tech" do
      expect(rendered).to have_css("svg.yui-icon[aria-hidden='true']")
    end
  end
end
