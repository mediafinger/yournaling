# frozen_string_literal: true

require "rails_helper"

RSpec.describe Example::CalloutComponent, type: :component do
  it "renders a note landmark with title and body" do
    rendered = render_inline(described_class.new(title: "Drafts autosave")) { "Saved every few seconds." }

    expect(rendered).to have_css("div.ex-callout[role='note']")
    expect(rendered).to have_css(".ex-callout__title", text: "Drafts autosave")
    expect(rendered).to have_css(".ex-callout__body", text: "Saved every few seconds.")
  end

  it "adds a modifier class for non-info variants and a decorative icon" do
    rendered = render_inline(described_class.new(variant: :danger, title: "Careful")) { "x" }

    expect(rendered).to have_css(".ex-callout.ex-callout--danger .ex-callout__icon svg.ex-icon[aria-hidden='true']")
  end

  it "falls back to info for an unknown variant" do
    rendered = render_inline(described_class.new(variant: :spicy)) { "x" }

    expect(rendered).to have_css(".ex-callout")
    expect(rendered).to have_no_css("[class*='ex-callout--']")
  end
end
