# frozen_string_literal: true

require "rails_helper"

RSpec.describe Yui::ButtonComponent, type: :component do
  it "renders a <button> with the primary variant by default" do
    rendered = render_inline(described_class.new("Save memory"))

    expect(rendered).to have_button("Save memory", type: "button", class: %w[ex-btn ex-btn--primary])
  end

  it "renders an <a role='button'> when given an href" do
    rendered = render_inline(described_class.new("Browse", href: "/browse"))

    expect(rendered).to have_link("Browse", href: "/browse", class: "ex-btn")
    expect(rendered.css("a[role='button']")).to be_present
    expect(rendered).to have_no_button
  end

  it "maps variant and size to modifier classes" do
    rendered = render_inline(described_class.new("Delete", variant: :danger, size: :sm))

    expect(rendered).to have_button("Delete", class: %w[ex-btn--danger ex-btn--sm])
  end

  it "falls back to the default variant for an unknown value" do
    rendered = render_inline(described_class.new("Hmm", variant: :nonsense))

    expect(rendered).to have_button("Hmm", class: "ex-btn--primary")
  end

  it "renders the disabled attribute and keeps the label readable" do
    rendered = render_inline(described_class.new("Unavailable", disabled: true))

    expect(rendered).to have_css("button[disabled]", text: "Unavailable")
  end

  describe "accessibility" do
    it "marks a leading icon as decorative" do
      rendered = render_inline(described_class.new("New", icon: "plus"))

      expect(rendered).to have_css("svg.ex-icon[aria-hidden='true']")
      expect(rendered).to have_css("button > span", text: "New")
    end
  end
end
