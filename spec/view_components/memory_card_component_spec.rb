# frozen_string_literal: true

require "rails_helper"

RSpec.describe MemoryCardComponent, type: :component do
  let(:team) { FactoryBot.build_stubbed(:team, name: "The Coast Year") }
  let(:memory) {
    FactoryBot.build_stubbed(:memory, weblink: nil, memo: "We found a whole sand dollar, unbroken.", team: team)
  }

  context "with actions: false (previews / static)" do
    def render_card(**)
      render_inline(described_class.new(memory: memory, actions: false, **))
    end

    it "renders the memo, the Memory badge and a plain meta line" do
      rendered = render_card(scope: :browse)

      expect(rendered).to have_css("article.ex-card.ex-memory-card##{ActionView::RecordIdentifier.dom_id(memory)}")
      expect(rendered).to have_css(".ex-memory-card__memo", text: "sand dollar")
      expect(rendered).to have_css(".ex-badge", text: "Memory")
      expect(rendered).to have_css(".ex-meta", text: "The Coast Year")
      expect(rendered).to have_no_css(".ex-record-header")
    end

    it "renders an attached thought as a blockquote" do
      memory.thought = Thought.new(text: "Some days keep themselves.")

      expect(render_card(scope: :browse)).to have_css(".ex-blockquote blockquote", text: "Some days keep themselves.")
    end

    it "renders an attached location as a chip" do
      memory.location = FactoryBot.build_stubbed(:location, name: "Ericeira", country_code: "pt")

      expect(render_card(scope: :browse)).to have_css("span.ex-tag", text: "Ericeira")
    end
  end

  context "with the real header (actions: true)" do
    it "renders the Browse header for scope: :browse" do
      rendered = render_inline(described_class.new(memory: memory, scope: :browse, team: team))

      expect(rendered).to have_css(".ex-record-header")
      expect(rendered).to have_css(".ex-record-header", text: "The Coast Year")
    end

    it "renders the Manage header for scope: :manage" do
      rendered = render_inline(described_class.new(memory: memory, scope: :manage, hide_actions: true))

      expect(rendered).to have_css(".ex-record-header")
    end
  end
end
