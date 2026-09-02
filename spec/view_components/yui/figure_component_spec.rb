# frozen_string_literal: true

require "rails_helper"

RSpec.describe Yui::FigureComponent, type: :component do
  let(:src) { "data:image/svg+xml,%3Csvg/%3E" }

  it "renders a <figure> with a framed image" do
    rendered = render_inline(described_class.new(src:, alt: "The beach at dusk"))

    expect(rendered).to have_css("figure.yui-figure .yui-figure__frame img[alt='The beach at dusk'][loading='lazy']")
  end

  it "renders a caption when given" do
    rendered = render_inline(described_class.new(src:, alt: "x", caption: "Day 4"))

    expect(rendered).to have_css("figure figcaption", text: "Day 4")
  end

  it "omits the caption element when none is given" do
    rendered = render_inline(described_class.new(src:, alt: "x"))

    expect(rendered).to have_no_css("figcaption")
  end

  it "adds a ratio modifier class for a known ratio" do
    rendered = render_inline(described_class.new(src:, alt: "x", ratio: "16/9"))

    expect(rendered).to have_css("figure.yui-figure--ratio-16-9")
  end
end
