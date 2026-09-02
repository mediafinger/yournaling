# frozen_string_literal: true

require "rails_helper"

RSpec.describe Yui::SpinnerComponent, type: :component do
  it "renders a status role with an animated ring" do
    rendered = render_inline(described_class.new)

    expect(rendered).to have_css("span.yui-spinner[role='status']")
    expect(rendered).to have_css("span.yui-spinner__ring[aria-hidden='true']")
  end

  it "exposes an accessible label when no visible label is given" do
    rendered = render_inline(described_class.new)

    expect(rendered).to have_css("span.yui-visually-hidden", text: "Loading")
  end

  it "shows a visible label when provided" do
    rendered = render_inline(described_class.new("Loading more stories…"))

    expect(rendered).to have_css("span.yui-spinner__label", text: "Loading more stories…")
    expect(rendered).to have_no_css("span.yui-visually-hidden")
  end

  it "adds a size modifier class" do
    rendered = render_inline(described_class.new(size: :lg))

    expect(rendered).to have_css("span.yui-spinner.yui-spinner--lg")
  end

  it "falls back to the default size for an unknown value" do
    rendered = render_inline(described_class.new(size: :bogus))

    expect(rendered).to have_css("span.yui-spinner")
    expect(rendered).to have_no_css("[class*='yui-spinner--']")
  end
end
