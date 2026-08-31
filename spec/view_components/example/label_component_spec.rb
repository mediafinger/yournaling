# frozen_string_literal: true

require "rails_helper"

RSpec.describe Example::LabelComponent, type: :component do
  it "renders a <label> bound to the given control id" do
    rendered = render_inline(described_class.new("Title", for: "memory_title"))

    expect(rendered).to have_css("label.ex-label[for='memory_title']", text: "Title")
  end

  it "shows a required marker hidden from assistive tech" do
    rendered = render_inline(described_class.new("Title", for: "t", required: true))

    expect(rendered).to have_css(".ex-label__required[aria-hidden='true']", text: "*")
  end

  it "shows an optional marker instead when optional: true" do
    rendered = render_inline(described_class.new("Notes", for: "n", optional: true))

    expect(rendered).to have_css(".ex-label__optional", text: "(optional)")
    expect(rendered).to have_no_css(".ex-label__required")
  end
end
