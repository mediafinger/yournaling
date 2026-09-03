# frozen_string_literal: true

require "rails_helper"

RSpec.describe RecordFooterComponent, type: :component do
  let(:team) { FactoryBot.create(:team, name: "RanTanVan") }
  let(:creator) { FactoryBot.create(:user, name: "Dana Rivers") }

  let(:chronicle) do
    FactoryBot.create(:chronicle, team: team, start_date: Date.new(2026, 7, 1), end_date: Date.new(2026, 7, 10))
  end
  let(:story) { FactoryBot.create(:story, team: team, date: Date.new(2026, 8, 3)) }

  describe "browse scope" do
    it "shows the date on the left and an @team link to the public timeline on the right" do
      rendered = render_inline(described_class.new(record: chronicle, scope: :browse, team: team))

      expect(rendered).to have_css(".yui-card-footer__date", text: "2026-07-01 – 2026-07-10")
      expect(rendered).to have_link("@RanTanVan", href: "/teams/#{team.to_param}")
      expect(rendered).to have_no_text("Unknown")
    end
  end

  describe "manage scope" do
    it "shows the creator's name from the created RecordEvent" do
      created = Story.new(name: "Trailhead", content: "We set off at dawn and walked.", date: Date.current, team: team)
      Story.create_with_event(record: created, event_params: { team: team, user: creator })

      rendered = render_inline(described_class.new(record: created, scope: :manage))

      expect(rendered).to have_css(".yui-card-footer__owner", text: "Dana Rivers")
      expect(rendered).to have_no_link("@RanTanVan")
    end

    it "falls back to 'Unknown' when there is no created event" do
      rendered = render_inline(described_class.new(record: story, scope: :manage))

      expect(rendered).to have_css(".yui-card-footer__owner", text: "Unknown")
    end

    it "uses the record's own date field when present" do
      rendered = render_inline(described_class.new(record: story, scope: :manage))

      expect(rendered).to have_css(".yui-card-footer__date", text: "2026-08-03")
    end
  end
end
