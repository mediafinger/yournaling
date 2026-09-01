# frozen_string_literal: true

require "rails_helper"

RSpec.describe ChronicleCardComponent, type: :component do
  let(:team) { FactoryBot.build_stubbed(:team, name: "The Coast Year") }
  let(:chronicle) do
    FactoryBot.build_stubbed(:chronicle, name: "A year on the coast", notice: "Twelve months of small tides.", team: team)
  end

  context "with actions: false (previews / static)" do
    def render_card(chronicle: nil, **)
      render_inline(described_class.new(chronicle: chronicle || self.chronicle, actions: false, **))
    end

    it "renders the eyebrow, its own title, the notice and a meta line" do
      rendered = render_card(scope: :browse)

      expect(rendered).to have_css("article.ex-card.ex-chronicle-card##{ActionView::RecordIdentifier.dom_id(chronicle)}")
      expect(rendered).to have_css(".ex-eyebrow", text: "Chronicle")
      expect(rendered).to have_css("h3", text: "A year on the coast")
      expect(rendered).to have_css(".ex-chronicle-card__summary", text: "Twelve months of small tides.")
      expect(rendered).to have_css(".ex-meta", text: "The Coast Year")
      expect(rendered).to have_no_css(".ex-record-header")
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

        expect(rendered).to have_css(".ex-timeline .ex-timeline__item", count: 2)
        expect(rendered).to have_css(".ex-timeline", text: "First swim of the year.")
      end

      it "does not render the timeline when not full" do
        expect(render_card(chronicle: with_entries, scope: :browse, full: false)).to have_no_css(".ex-timeline")
      end
    end
  end

  it "renders the Browse header (no buttons for a guest) when actions: true" do
    chronicle = FactoryBot.create(:chronicle, team: FactoryBot.create(:team, name: "The Coast Year"),
      visibility: "published")

    rendered = render_inline(described_class.new(chronicle: chronicle, scope: :browse, team: chronicle.team))

    expect(rendered).to have_css(".ex-record-header", text: "The Coast Year")
  end
end
