# frozen_string_literal: true

require "rails_helper"

RSpec.describe RecordFooterComponent, type: :component do
  let(:team) { FactoryBot.create(:team, name: "RanTanVan") }
  let(:creator) { FactoryBot.create(:user, name: "Dana Rivers") }

  let(:chronicle) do
    FactoryBot.create(:chronicle, team: team, start_date: Date.new(2026, 7, 1), end_date: Date.new(2026, 7, 10),
      visibility: "internal")
  end
  let(:story) { FactoryBot.create(:story, team: team, date: Date.new(2026, 8, 3)) }

  describe "browse scope" do
    it "shows the date on the left and an @team link to the public timeline on the right — no visibility control" do
      rendered = render_inline(described_class.new(record: chronicle, scope: :browse, team: team))

      expect(rendered).to have_css(".yui-card-footer__date", text: "2026-07-01 – 2026-07-10")
      expect(rendered).to have_link("@RanTanVan", href: "/teams/#{team.to_param}")
      expect(rendered).to have_no_text("Unknown")
      expect(rendered).to have_no_css(".yui-card-footer__center")
    end

    it "renders a caller-supplied center slot (e.g. a 'Show more' link)" do
      rendered = render_inline(described_class.new(record: chronicle, scope: :browse, team: team)) do |footer|
        footer.with_center { "Show more" }
      end

      expect(rendered).to have_css(".yui-card-footer__center", text: "Show more")
    end

    context "when the viewer may edit the record" do
      let(:user) { FactoryBot.create(:user) }
      let!(:member) { Member.create!(team: team, user: user, roles: %w[owner publisher]) }

      it "renders Rewrite directly before the @team handle" do
        rendered = render_inline(described_class.new(record: chronicle, scope: :browse, team: team, user: user,
          member: member))

        expect(rendered).to have_link("Rewrite", href: "/current_team/chronicles/#{chronicle.to_param}/edit")
        expect(rendered).to have_css(".yui-card-footer__owner-group a[aria-label='Rewrite']")
        expect(rendered).to have_css(".yui-card-footer__owner-group", text: "@RanTanVan")
      end
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

    context "when the viewer may change visibility" do
      let(:user) { FactoryBot.create(:user) }
      let!(:member) { Member.create!(team: team, user: user, roles: %w[owner publisher]) }

      it "renders the visibility control (primary button showing the state) centered" do
        rendered = render_inline(described_class.new(record: chronicle, scope: :manage, team: team, user: user,
          member: member))

        expect(rendered).to have_css(".yui-card-footer__center button[aria-label='Change visibility']", text: "Internal")
      end

      it "renders Rewrite before the creator's name" do
        rendered = render_inline(described_class.new(record: chronicle, scope: :manage, team: team, user: user,
          member: member))

        expect(rendered).to have_link("Rewrite", href: "/current_team/chronicles/#{chronicle.to_param}/edit")
      end
    end

    context "when the viewer may not change visibility" do
      it "renders a static badge instead of the modal trigger" do
        editor = FactoryBot.create(:user)
        editor_member = Member.create!(team: team, user: editor, roles: %w[editor])
        published = FactoryBot.create(:chronicle, team: team, visibility: "published")

        rendered = render_inline(described_class.new(record: published, scope: :manage, team: team, user: editor,
          member: editor_member))

        expect(rendered).to have_css(".yui-card-footer__center .yui-badge", text: "Published")
        expect(rendered).to have_no_css("button[aria-label='Change visibility']")
      end
    end

    context "with show_rewrite / show_visibility disabled (e.g. embedded content)" do
      let(:user) { FactoryBot.create(:user) }
      let!(:member) { Member.create!(team: team, user: user, roles: %w[owner publisher]) }

      it "suppresses both regardless of authorization" do
        rendered = render_inline(described_class.new(record: chronicle, scope: :manage, team: team, user: user,
          member: member, show_rewrite: false, show_visibility: false))

        expect(rendered).to have_no_link("Rewrite")
        expect(rendered).to have_no_css(".yui-card-footer__center")
      end
    end
  end
end
