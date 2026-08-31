# frozen_string_literal: true

require "rails_helper"

RSpec.describe Example::BadgeComponent, type: :component do
  it "renders a span with the label" do
    rendered = render_inline(described_class.new("Published"))

    expect(rendered).to have_css("span.ex-badge", text: "Published")
  end

  it "adds a modifier class for non-neutral variants" do
    rendered = render_inline(described_class.new("Published", variant: :success))

    expect(rendered).to have_css("span.ex-badge.ex-badge--success")
  end

  it "renders a decorative dot when requested" do
    rendered = render_inline(described_class.new("Live", dot: true))

    expect(rendered).to have_css("span.ex-badge__dot")
  end

  it "renders a decorative icon" do
    rendered = render_inline(described_class.new("Team", icon: "user"))

    expect(rendered).to have_css("svg.ex-icon[aria-hidden='true']")
  end

  it "falls back to neutral for an unknown variant" do
    rendered = render_inline(described_class.new("X", variant: :bogus))

    expect(rendered).to have_css("span.ex-badge")
    expect(rendered).to have_no_css("[class*='ex-badge--']")
  end
end
