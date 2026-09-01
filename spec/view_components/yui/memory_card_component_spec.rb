# frozen_string_literal: true

require "rails_helper"

RSpec.describe Yui::MemoryCardComponent, type: :component do
  def render_card(**overrides)
    defaults = {
      memo: "We found a whole sand dollar, unbroken.", on: "4 Aug 2024",
      author: "Mira Kessler", team: "The Coast Year"
    }
    render_inline(described_class.new(**defaults, **overrides))
  end

  it "renders the memo, author and date, composed from primitives" do
    rendered = render_card

    expect(rendered).to have_css(".ex-memory-card .ex-memory-card__memo", text: "We found a whole sand dollar")
    expect(rendered).to have_css(".ex-meta", text: "Mira Kessler")
    expect(rendered).to have_css(".ex-meta", text: "4 Aug 2024")
    expect(rendered).to have_css(".ex-avatar", text: "MK")
  end

  it "shows the visibility as a badge" do
    expect(render_card(visibility: :team)).to have_css(".ex-badge.ex-badge--info", text: "Team")
    expect(render_card(visibility: :private)).to have_css(".ex-badge", text: "Private")
  end

  it "renders location and tags as chips" do
    rendered = render_card(location: "Ericeira", tags: %w[beach walk])

    expect(rendered).to have_css(".ex-tag", text: "Ericeira")
    expect(rendered).to have_css(".ex-tag", text: "beach")
    expect(rendered).to have_css(".ex-tag", text: "walk")
  end

  it "renders an optional pulled thought and cover image" do
    rendered = render_card(thought: "Some days keep themselves.", image: "data:image/svg+xml,%3Csvg/%3E")

    expect(rendered).to have_css(".ex-memory-card__quote", text: "Some days keep themselves.")
    expect(rendered).to have_css(".ex-card__media img")
  end

  it "becomes a link when given an href" do
    expect(render_card(href: "/memories/1")).to have_link(href: "/memories/1", class: "ex-card")
  end
end
