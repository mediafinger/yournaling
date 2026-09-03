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

    it "renders the truncated memo as an h4, the memo body and a meta line — no 'Memory' badge, no record-header" do
      rendered = render_card(scope: :browse)

      expect(rendered).to have_css("article.yui-card.yui-memory-card##{ActionView::RecordIdentifier.dom_id(memory)}")
      expect(rendered).to have_css("h4", text: "We found a whole sand dollar, unbroken.")
      expect(rendered).to have_css(".yui-memory-card__memo", text: "sand dollar")
      expect(rendered).to have_no_css(".yui-badge")
      expect(rendered).to have_css(".yui-meta", text: "The Coast Year")
      expect(rendered).to have_no_css(".yui-record-header")
      expect(rendered).to have_css(".yui-card-footer")
    end

    it "renders an attached thought as a blockquote" do
      memory.thought = Thought.new(text: "Some days keep themselves.")

      expect(render_card(scope: :browse)).to have_css(".yui-blockquote blockquote", text: "Some days keep themselves.")
    end

    it "renders an attached location as a chip" do
      memory.location = FactoryBot.build_stubbed(:location, name: "Ericeira", country_code: "pt")

      expect(render_card(scope: :browse)).to have_css("span.yui-tag", text: "Ericeira")
    end
  end

  context "with the real header (actions: true)" do
    it "renders the Browse header with the memo as the h4 name and an @team footer link" do
      rendered = render_inline(described_class.new(memory: memory, scope: :browse, team: team))

      expect(rendered).to have_css(".yui-record-header h4.yui-record-header__title", text: "We found a whole sand dollar")
      expect(rendered).to have_link("@The Coast Year", href: "/teams/#{team.to_param}")
    end

    it "renders the Manage header for scope: :manage" do
      rendered = render_inline(described_class.new(memory: memory, scope: :manage, hide_actions: true))

      expect(rendered).to have_css(".yui-record-header")
    end
  end
end
