# frozen_string_literal: true

require "rails_helper"

RSpec.describe Yui::CardComponent, type: :component do
  it "renders an <article> with the body content" do
    rendered = render_inline(described_class.new) { "Body text" }

    expect(rendered).to have_css("article.ex-card .ex-card__body", text: "Body text")
  end

  it "adds a modifier class for non-default variants" do
    rendered = render_inline(described_class.new(variant: :elevated)) { "x" }

    expect(rendered).to have_css("article.ex-card.ex-card--elevated")
  end

  it "renders as an <a> and is interactive when given an href" do
    rendered = render_inline(described_class.new(href: "/memories/1")) { "x" }

    expect(rendered).to have_link(href: "/memories/1", class: %w[ex-card ex-card--interactive])
  end

  it "exposes the accent colour as a custom property" do
    rendered = render_inline(described_class.new(accent: "gold")) { "x" }

    card = rendered.css(".ex-card").first
    expect(card[:class]).to include("ex-card--accent")
    expect(card[:style]).to include("--ex-card-accent: var(--ex-gold)")
  end

  it "renders header, media and footer slots" do
    rendered = render_inline(described_class.new) do |card|
      card.with_header { "H" }
      card.with_media { "M" }
      card.with_footer { "F" }
      "Body"
    end

    expect(rendered).to have_css(".ex-card__media", text: "M")
    expect(rendered).to have_css(".ex-card__header", text: "H")
    expect(rendered).to have_css(".ex-card__footer", text: "F")
  end
end
