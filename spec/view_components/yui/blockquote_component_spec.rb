# frozen_string_literal: true

require "rails_helper"

RSpec.describe Yui::BlockquoteComponent, type: :component do
  it "renders a figure with a blockquote" do
    rendered = render_inline(described_class.new("We travel to lose ourselves."))

    expect(rendered).to have_css("figure.yui-blockquote blockquote", text: "We travel to lose ourselves.")
  end

  it "renders attribution in a figcaption when cite is given" do
    rendered = render_inline(described_class.new("A quote", cite: "Field notes"))

    expect(rendered).to have_css("figure.yui-blockquote figcaption", text: "— Field notes")
  end

  it "omits the figcaption without a cite" do
    rendered = render_inline(described_class.new("A quote"))

    expect(rendered).to have_no_css("figcaption")
  end

  it "adds the card modifier class" do
    rendered = render_inline(described_class.new("A quote", variant: :card))

    expect(rendered).to have_css("figure.yui-blockquote.yui-blockquote--card")
  end

  it "accepts block content" do
    rendered = render_inline(described_class.new(cite: "x")) { "The tide took the rest." }

    expect(rendered).to have_css("blockquote", text: "The tide took the rest.")
  end
end
