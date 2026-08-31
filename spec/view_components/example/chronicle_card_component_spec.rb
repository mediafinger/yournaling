# frozen_string_literal: true

require "rails_helper"

RSpec.describe Example::ChronicleCardComponent, type: :component do
  def render_card(**overrides)
    defaults = {
      title: "A year on the coast", summary: "Twelve months of small tides.",
      start_date: "Jan 2024", author: "Andreas Finger", team: "The Coast Year"
    }
    render_inline(described_class.new(**defaults, **overrides))
  end

  it "renders the eyebrow, title and summary" do
    rendered = render_card

    expect(rendered).to have_css(".ex-chronicle-card .ex-eyebrow", text: "Chronicle")
    expect(rendered).to have_css("h3", text: "A year on the coast")
    expect(rendered).to have_css(".ex-chronicle-card__summary", text: "Twelve months of small tides.")
  end

  it "formats an open-ended vs closed date range" do
    expect(render_card).to have_css(".ex-chronicle-card__dates", text: "Since Jan 2024")
    expect(render_card(end_date: "Dec 2024")).to have_css(".ex-chronicle-card__dates", text: "Jan 2024 – Dec 2024")
  end

  it "renders up to four entries on a timeline" do
    entries = Array.new(6) { |i| { title: "Entry #{i}", date: "#{i} Jan" } }
    rendered = render_card(entries:)

    expect(rendered).to have_css(".ex-timeline .ex-timeline__item", count: 4)
    expect(rendered).to have_css(".ex-timeline__title", text: "Entry 0")
  end

  it "shows the memory count and an Open link when linkable" do
    rendered = render_card(memory_count: 48, href: "#")

    expect(rendered).to have_css(".ex-badge", text: "48 memories")
    expect(rendered).to have_css("a.ex-link--standalone", text: "Open")
    expect(rendered).to have_css("h3 a.ex-link", text: "A year on the coast")
  end
end
