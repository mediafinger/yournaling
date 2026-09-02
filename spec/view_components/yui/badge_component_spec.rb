# frozen_string_literal: true

require "rails_helper"

RSpec.describe Yui::BadgeComponent, type: :component do
  it "renders a span with the label" do
    rendered = render_inline(described_class.new("Published"))

    expect(rendered).to have_css("span.yui-badge", text: "Published")
  end

  it "adds a modifier class for non-neutral variants" do
    rendered = render_inline(described_class.new("Published", variant: :success))

    expect(rendered).to have_css("span.yui-badge.yui-badge--success")
  end

  it "renders a decorative dot when requested" do
    rendered = render_inline(described_class.new("Live", dot: true))

    expect(rendered).to have_css("span.yui-badge__dot")
  end

  it "renders a decorative icon" do
    rendered = render_inline(described_class.new("Team", icon: "user"))

    expect(rendered).to have_css("svg.yui-icon[aria-hidden='true']")
  end

  it "falls back to neutral for an unknown variant" do
    rendered = render_inline(described_class.new("X", variant: :bogus))

    expect(rendered).to have_css("span.yui-badge")
    expect(rendered).to have_no_css("[class*='yui-badge--']")
  end
end
