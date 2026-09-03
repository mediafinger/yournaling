# frozen_string_literal: true

require "rails_helper"

RSpec.describe ChronicleCardComponent, type: :component do
  let(:team) { FactoryBot.build_stubbed(:team, name: "The Coast Year") }
  let(:chronicle) do
    FactoryBot.build_stubbed(:chronicle, name: "A year on the coast", notice: "Twelve months of small tides.", team: team,
      start_date: Date.new(2024, 1, 1))
  end

  context "with actions: false (previews / static)" do
    def render_card(chronicle: nil, **)
      render_inline(described_class.new(chronicle: chronicle || self.chronicle, actions: false, **))
    end

    it "renders an h4 title, the notice, a meta line and a footer — no eyebrow, no record-header" do
      rendered = render_card(scope: :browse)

      expect(rendered).to have_css("article.yui-card.yui-chronicle-card##{ActionView::RecordIdentifier.dom_id(chronicle)}")
      expect(rendered).to have_no_css(".yui-eyebrow")
      expect(rendered).to have_css("h4", text: "A year on the coast")
      expect(rendered).to have_css(".yui-chronicle-card__summary", text: "Twelve months of small tides.")
      expect(rendered).to have_css(".yui-meta", text: "The Coast Year")
      expect(rendered).to have_no_css(".yui-record-header")
      expect(rendered).to have_css(".yui-card-footer")
    end

    context "with entries (built in memory)" do
      let(:with_entries) do
        Chronicle.new(
          name: "A year on the coast", notice: "n", start_date: Date.new(2024, 1, 1), team: team,
          entries: [
            ChronicleEntry.new(entry: Thought.new(text: "First swim of the year.")),
            ChronicleEntry.new(entry: Thought.new(text: "Storm week.")),
          ]
        )
      end

      it "renders a timeline of entries when full" do
        rendered = render_card(chronicle: with_entries, scope: :browse, full: true)

        expect(rendered).to have_css(".yui-timeline .yui-timeline__item", count: 2)
        expect(rendered).to have_css(".yui-timeline", text: "First swim of the year.")
      end

      it "does not render the timeline when not full" do
        expect(render_card(chronicle: with_entries, scope: :browse, full: false)).to have_no_css(".yui-timeline")
      end
    end
  end

  it "renders the Browse header (h4 name, no buttons for a guest) and an @team footer link when actions: true" do
    chronicle = FactoryBot.create(:chronicle, team: FactoryBot.create(:team, name: "The Coast Year"),
      visibility: "published")

    rendered = render_inline(described_class.new(chronicle: chronicle, scope: :browse, team: chronicle.team))

    expect(rendered).to have_css(".yui-record-header h4.yui-record-header__title", text: chronicle.name)
    expect(rendered).to have_css(".yui-record-header", text: chronicle.name)
    expect(rendered).to have_link("@The Coast Year", href: "/teams/#{chronicle.team.to_param}")
  end
end
