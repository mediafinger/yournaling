# frozen_string_literal: true

require "rails_helper"

RSpec.describe ManageHeaderComponent, type: :component do
  let(:team) { FactoryBot.create(:team) }
  let(:user) { FactoryBot.create(:user) }
  let!(:member) { Member.create!(team: team, user: user, roles: %w[owner publisher]) }

  let(:chronicle) do
    FactoryBot.create(:chronicle, team: team, name: "Desert Journey", start_date: "2024-01-01", end_date: "2024-01-10",
      visibility: "internal")
  end
  let(:thought) do
    FactoryBot.create(:thought, team: team, text: "A deep and meandering thought about tides", visibility: "internal")
  end

  describe "actions_in_header: true (default) — Member's unchanged layout" do
    it "renders the member's name as plain text, with Open, Rewrite and a visibility button — no 'Visibility:' label" do
      rendered = render_inline(described_class.new(record: member, user: user, team: team, member: member))

      expect(rendered.to_html).to have_css("h4.yui-record-header__title", text: user.name)
      expect(rendered.to_html).to have_no_css("h4.yui-record-header__title a")
      expect(rendered.to_html).to have_link("Open", href: "/current_team/members/#{member.to_param}")
      expect(rendered.to_html).to have_link("Rewrite", href: "/current_team/members/#{member.to_param}/edit")
      expect(rendered.to_html).to have_css("button[aria-label='Change visibility']")
      expect(rendered.to_html).not_to include("Visibility:")
    end

    it "renders a static visibility badge (no modal) when the user may not change visibility" do
      editor = FactoryBot.create(:user)
      editor_member = Member.create!(team: team, user: editor, roles: %w[editor])
      other_member = Member.create!(team: team, user: FactoryBot.create(:user), roles: %w[editor])

      rendered = render_inline(described_class.new(record: other_member, user: editor, team: team, member: editor_member))

      expect(rendered.to_html).to have_css(".yui-badge")
      expect(rendered.to_html).to have_no_css("button[aria-label='Change visibility']")
      expect(rendered.to_html).to have_no_css("dialog")
    end

    it "suppresses actions and the visibility control when hide_actions is true" do
      rendered = render_inline(described_class.new(record: member, user: user, team: team, member: member,
        hide_actions: true))

      expect(rendered.to_html).to have_no_link("Open")
      expect(rendered.to_html).to have_no_link("Rewrite")
      expect(rendered.to_html).to have_no_css("dialog")
      expect(rendered.to_html).to have_no_css(".yui-badge")
    end

    it "renders in a guest context (no user/member) without raising" do
      expect { render_inline(described_class.new(record: member, team: team)) }.not_to raise_error
    end
  end

  describe "actions_in_header: false — Chronicle and the manage insight cards" do
    it "renders the chronicle name as a linked h4 — no Open/Rewrite/visibility in the header" do
      rendered = render_inline(described_class.new(record: chronicle, team: team, actions_in_header: false))

      expect(rendered.to_html).to have_css("h4.yui-record-header__title a.yui-link--cover", text: "Desert Journey")
      expect(rendered.to_html).to have_no_link("Open")
      expect(rendered.to_html).to have_no_link("Rewrite")
      expect(rendered.to_html).to have_no_css("button[aria-label='Change visibility']")
      expect(rendered.to_html).to have_no_css(".yui-badge")
    end

    it "renders the truncated text as the thought title" do
      rendered = render_inline(described_class.new(record: thought, team: team, actions_in_header: false))

      expect(rendered.to_html).to have_css("h4.yui-record-header__title", text: "A deep and meandering thought about tides")
    end

    it "does not link the title when already on the record's own show page" do
      allow_any_instance_of(described_class).to receive(:action_name).and_return("show") # rubocop:disable RSpec/AnyInstance

      rendered = render_inline(described_class.new(record: chronicle, team: team, actions_in_header: false))

      expect(rendered.to_html).to have_css("h4.yui-record-header__title", text: "Desert Journey")
      expect(rendered.to_html).to have_no_css("h4.yui-record-header__title a")
    end
  end
end
