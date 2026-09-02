# frozen_string_literal: true

require "rails_helper"

RSpec.describe Yui::HeadlineComponent, type: :component do
  it "renders the semantic heading tag for the given level" do
    (1..4).each do |level|
      rendered = render_inline(described_class.new("Title", level:))
      expect(rendered).to have_css("h#{level}.yui-h#{level}", text: "Title")
    end
  end

  it "clamps an out-of-range level to 2" do
    rendered = render_inline(described_class.new("Title", level: 9))

    expect(rendered).to have_css("h2")
  end

  it "renders an eyebrow above the heading when given" do
    rendered = render_inline(described_class.new("A year on the coast", level: 1, eyebrow: "Chronicle"))

    expect(rendered).to have_css("p.yui-eyebrow", text: "Chronicle")
    expect(rendered).to have_css("h1", text: "A year on the coast")
  end

  it "uses the oversized display treatment when display: true" do
    rendered = render_inline(described_class.new("Kept for good", level: 1, display: true))

    expect(rendered).to have_css("h1.yui-display")
  end

  it "accepts block content" do
    rendered = render_inline(described_class.new(level: 3)) { "From a block" }

    expect(rendered).to have_css("h3", text: "From a block")
  end
end
