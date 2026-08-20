# frozen_string_literal: true

require "rails_helper"

RSpec.describe TeamSwitcherAndSessionsComponent, type: :component do
  let(:team) { FactoryBot.create(:team, name: "Alpha Squad") }
  let(:user) { FactoryBot.create(:user, name: "Alice Admin", role: "admin") }

  before do
    Member.create!(team: team, user: user, roles: %w[owner]) if user&.persisted? && team
    allow_any_instance_of(described_class).to receive(:current_user).and_return(user) # rubocop:disable RSpec/AnyInstance
    allow_any_instance_of(described_class).to receive(:current_team).and_return(team) # rubocop:disable RSpec/AnyInstance
    allow_any_instance_of(described_class).to receive(:active_path?).and_return(false) # rubocop:disable RSpec/AnyInstance
  end

  context "when user is an admin in browse mode" do
    it "renders admin area, switch team, logins, and logout" do
      rendered = render_inline(described_class.new(mode: :browse))

      expect(rendered.to_html).to have_link("🛡️ Admin Area", href: "/admin")
      expect(rendered.to_html).to have_link("Switch Team", href: "/switch_current_teams")
      expect(rendered.to_html).to have_link("👤 Alice Admin", href: "/logins")
      expect(rendered.to_html).to have_button("Logout")
    end
  end

  context "when user is in admin mode" do
    it "renders scope to team and logout but no admin link" do
      rendered = render_inline(described_class.new(mode: :admin))

      expect(rendered.to_html).to have_no_link("🛡️ Admin Area", href: "/admin")
      expect(rendered.to_html).to have_css(".scope-to-team", text: "Scope to Team")
      expect(rendered.to_html).to have_link("👤 Alice Admin", href: "/logins")
      expect(rendered.to_html).to have_button("Logout")
    end
  end

  context "when user is a guest" do
    let(:user) { User.new }

    before do
      allow_any_instance_of(described_class).to receive(:current_team).and_return(nil) # rubocop:disable RSpec/AnyInstance
    end

    it "renders login link" do
      rendered = render_inline(described_class.new(mode: :browse))

      expect(rendered.to_html).to have_link("Login", href: "/login")
      expect(rendered.to_html).to have_no_button("Logout")
    end
  end
end
