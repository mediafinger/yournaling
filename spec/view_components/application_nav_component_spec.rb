# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationNavComponent, type: :component do
  let(:team) { FactoryBot.create(:team, name: "Alpha Squad") }
  let(:user) { FactoryBot.create(:user, name: "Alice Admin", role: "admin") }

  before do
    Member.create!(team: team, user: user, roles: %w[owner]) if user&.persisted? && team
    allow_any_instance_of(ApplicationComponent).to receive(:current_user).and_return(user) # rubocop:disable RSpec/AnyInstance
    allow_any_instance_of(ApplicationComponent).to receive(:current_team).and_return(team) # rubocop:disable RSpec/AnyInstance
    allow_any_instance_of(ApplicationComponent).to receive(:active_path?).and_return(false) # rubocop:disable RSpec/AnyInstance
  end

  context "when user is an admin with an active team" do
    it "renders left and center navigation links" do
      rendered = render_inline(described_class.new)

      expect(rendered.to_html).to have_link("🌐 Yournaling", href: "/")
      expect(rendered.to_html).to have_link("⚙️ Manage Alpha Squad", href: "/current_team")
      expect(rendered.to_html).to have_link("@Teams", href: "/teams")
      expect(rendered.to_html).to have_link("@@Members", href: "/teams/#{team.to_param}/members")
      expect(rendered.to_html).to have_link("🔍 Search", href: "/search")
    end

    it "renders right zone admin and session controls" do
      rendered = render_inline(described_class.new)

      expect(rendered.to_html).to have_link("🛡️ Admin Area", href: "/admin")
      expect(rendered.to_html).to have_link("Switch Team", href: "/switch_current_teams")
      expect(rendered.to_html).to have_link("👤 Alice Admin", href: "/logins")
      expect(rendered.to_html).to have_button("Logout")
    end
  end

  context "when user is a regular non-admin" do
    let(:user) { FactoryBot.create(:user, name: "Bob Member", role: "user") }

    it "does not render admin area link" do
      rendered = render_inline(described_class.new)

      expect(rendered.to_html).to have_link("🌐 Yournaling", href: "/")
      expect(rendered.to_html).to have_no_link("🛡️ Admin Area", href: "/admin")
      expect(rendered.to_html).to have_link("⚙️ Manage Alpha Squad", href: "/current_team")
      expect(rendered.to_html).to have_link("@Teams", href: "/teams")
      expect(rendered.to_html).to have_link("🔍 Search", href: "/search")
      expect(rendered.to_html).to have_link("👤 Bob Member", href: "/logins")
      expect(rendered.to_html).to have_button("Logout")
    end
  end

  context "when user has no active team" do
    before do
      allow_any_instance_of(ApplicationComponent).to receive(:current_team).and_return(nil) # rubocop:disable RSpec/AnyInstance
    end

    it "does not render manage team button or team members button" do
      rendered = render_inline(described_class.new)

      expect(rendered.to_html).to have_link("🌐 Yournaling", href: "/")
      expect(rendered.to_html).to have_no_link("⚙️ Manage Alpha Squad", href: "/current_team")
      expect(rendered.to_html).to have_link("@Teams", href: "/teams")
      expect(rendered.to_html).to have_link("🔍 Search", href: "/search")
    end
  end

  context "when user is not logged in (guest)" do
    let(:user) { User.new }

    before do
      allow_any_instance_of(ApplicationComponent).to receive(:current_team).and_return(nil) # rubocop:disable RSpec/AnyInstance
    end

    it "renders home, teams, search, and login button" do
      rendered = render_inline(described_class.new)

      expect(rendered.to_html).to have_link("🌐 Yournaling", href: "/")
      expect(rendered.to_html).to have_no_link("🛡️ Admin Area", href: "/admin")
      expect(rendered.to_html).to have_no_link("⚙️ Manage Alpha Squad", href: "/current_team")
      expect(rendered.to_html).to have_link("@Teams", href: "/teams")
      expect(rendered.to_html).to have_link("🔍 Search", href: "/search")
      expect(rendered.to_html).to have_link("Login", href: "/login")
      expect(rendered.to_html).to have_no_button("Logout")
    end
  end
end
