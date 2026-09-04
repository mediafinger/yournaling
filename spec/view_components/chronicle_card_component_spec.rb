# frozen_string_literal: true

require "rails_helper"

RSpec.describe ChronicleCardComponent, type: :component do
  let(:team) { FactoryBot.create(:team, name: "The Coast Year") }
  let(:chronicle) do
    FactoryBot.create(:chronicle, name: "A year on the coast", notice: "Twelve months of small tides on the coast.",
      team: team, start_date: Date.new(2024, 1, 1), visibility: "published")
  end

  describe "browse scope" do
    it "renders the name as a linked h4 title, the notice, and a footer with the @team handle — no eyebrow" do
      rendered = render_inline(described_class.new(chronicle: chronicle, scope: :browse, team: team))

      expect(rendered).to have_css("article.yui-card.yui-chronicle-card[id='#{ActionView::RecordIdentifier.dom_id(chronicle)}']")
      expect(rendered).to have_no_css(".yui-eyebrow")
      expect(rendered).to have_css("h4.yui-record-header__title a.yui-link--cover", text: "A year on the coast")
      expect(rendered).to have_css(".yui-chronicle-card__summary", text: "Twelve months of small tides on the coast.")
      expect(rendered).to have_link("@The Coast Year", href: "/teams/#{team.to_param}")
      expect(rendered).to have_no_css(".yui-btn", text: "Open")
    end

    context "with entries" do
      let!(:entries) do
        [
          ChronicleEntry.create!(chronicle: chronicle, team: team,
            entry: Thought.create!(team: team, text: "First swim of the year."), position: 1),
          ChronicleEntry.create!(chronicle: chronicle, team: team, entry: Thought.create!(team: team, text: "Storm week."),
            position: 2),
        ]
      end

      it "does not render the timeline outright, but offers a 'Show more' toggle with the hidden timeline" do
        rendered = render_inline(described_class.new(chronicle: chronicle, scope: :browse, team: team, full: false))

        expect(rendered).to have_no_css(".yui-timeline", visible: :visible)
        expect(rendered).to have_css("[data-controller='card-expand']")
        expect(rendered).to have_css(".yui-card-footer__center a", text: "Show more")
        expect(rendered).to have_css("[data-card-expand-target='entries'][hidden] .yui-timeline .yui-timeline__item",
          count: 2, visible: :all)
      end

      it "renders the timeline outright, with no 'Show more', when full" do
        rendered = render_inline(described_class.new(chronicle: chronicle, scope: :browse, team: team, full: true))

        expect(rendered).to have_css(".yui-timeline .yui-timeline__item", count: 2)
        expect(rendered).to have_no_css("[data-controller='card-expand']")
        expect(rendered).to have_no_text("Show more")
      end
    end

    it "does not offer 'Show more' when there are no entries" do
      rendered = render_inline(described_class.new(chronicle: chronicle, scope: :browse, team: team, full: false))

      expect(rendered).to have_no_css("[data-controller='card-expand']")
      expect(rendered).to have_no_text("Show more")
    end
  end

  describe "manage scope" do
    it "renders the name as a linked h4 title with no Open button in the header" do
      rendered = render_inline(described_class.new(chronicle: chronicle, scope: :manage, team: team))

      expect(rendered).to have_css(".yui-record-header h4.yui-record-header__title a.yui-link--cover",
        text: "A year on the coast")
      expect(rendered).to have_no_css(".yui-record-header .yui-btn", text: "Open")
    end

    it "wires the footer with show_rewrite / show_visibility off when hide_actions is true" do
      rendered = render_inline(described_class.new(chronicle: chronicle, scope: :manage, team: team, hide_actions: true))

      expect(rendered).to have_no_css(".yui-btn", text: "Rewrite")
      expect(rendered).to have_no_css(".yui-card-footer__center")
    end
  end

  # Rewrite / the visibility control appearing for an authorized viewer is
  # RecordFooterComponent's own responsibility (see its spec); covered here
  # end-to-end via a signed-in session in
  # spec/requests/current_teams/chronicles_request_spec.rb and
  # spec/requests/teams/chronicles_request_spec.rb.
end
