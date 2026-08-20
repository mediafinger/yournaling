# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Navigation Bars across Modes", type: :system do
  let(:team) { FactoryBot.create(:team, name: "Polar Explorers") }
  let(:member_user) { FactoryBot.create(:user, name: "Bob Member", email: "bob@example.com") }
  let(:admin_user) { FactoryBot.create(:user, name: "Alice Admin", email: "admin@example.com", role: "admin") }

  let!(:member) { Member.create!(team: team, user: member_user, roles: %w[owner]) }
  let!(:admin_member) { Member.create!(team: team, user: admin_user, roles: %w[owner]) }

  def login_as(user)
    visit login_url
    fill_in :email, with: user.email
    fill_in :password, with: "foobar1234"
    click_button "Login"
  end

  describe "Browse Mode Navbar" do
    it "renders guest navbar when not logged in" do
      visit root_url

      expect(page).to have_link("🌐 Yournaling", href: "/")
      expect(page).to have_link("+ New", href: "/login")
      expect(page).to have_link("@Teams", href: "/teams")
      expect(page).to have_link("🔍 Search", href: "/search")
      expect(page).to have_link("Login", href: "/login")
      expect(page).to have_no_button("Logout")
    end

    it "renders member navbar when logged in" do
      login_as(member_user)
      visit_switch_current_team(team)
      visit root_url

      expect(page).to have_link("🌐 Yournaling", href: "/")
      expect(page).to have_link("⚙️ Manage Polar Explorers", href: "/current_team")
      expect(page).to have_css("details.dropdown summary", text: "+ New")
      expect(page).to have_link("@Teams", href: "/teams")
      expect(page).to have_link("🔍 Search", href: "/search")
      expect(page).to have_link("Switch Team", href: "/switch_current_teams")
      expect(page).to have_link("👤 Bob Member", href: "/logins")
      expect(page).to have_button("Logout")
    end
  end

  describe "Manage Mode Navbar" do
    it "renders team timeline, post links, insights dropdown, and session links" do
      login_as(member_user)
      visit_switch_current_team(team)
      visit current_team_home_url

      expect(page).to have_link("🌐 Yournaling", href: "/")
      expect(page).to have_link("Manage Polar Explorers", href: "/current_team")
      expect(page).to have_css("details.dropdown summary", text: "+ New")
      expect(page).to have_link("Chronicles", href: "/current_team/chronicles")
      expect(page).to have_link("Memories", href: "/current_team/memories")
      expect(page).to have_css("details.dropdown summary", text: "Insights")
      expect(page).to have_link("Members", href: "/current_team/members")
      expect(page).to have_link("🔍 Search", href: "/current_team/new_search")
      expect(page).to have_link("Switch Team", href: "/switch_current_teams")
      expect(page).to have_link("👤 Bob Member", href: "/logins")
      expect(page).to have_button("Logout")
    end
  end

  describe "Admin Mode Navbar" do
    it "renders admin branding, management links, insight dropdown, and logout" do
      login_as(admin_user)
      visit "/admin"

      expect(page).to have_link("🛡️ Admin Area", href: "/admin")
      expect(page).to have_link("⬅ Exit Admin", href: "/")
      expect(page).to have_css("details.dropdown summary", text: "+ New")
      expect(page).to have_link("Users", href: "/admin/users")
      expect(page).to have_link("Teams", href: "/admin/teams")
      expect(page).to have_link("Members", href: "/admin/members")
      expect(page).to have_link("Chronicles", href: "/admin/chronicles")
      expect(page).to have_link("Memories", href: "/admin/memories")
      expect(page).to have_css("details.dropdown summary", text: "Insights")
      expect(page).to have_link("Record Events", href: "/admin/record_events")
      expect(page).to have_link("Analytics", href: "/admin/blazer")
      expect(page).to have_link("Jobs", href: "/admin/jobs")
      expect(page).to have_css(".scope-to-team", text: "Scope to Team")
      expect(page).to have_link("👤 Alice Admin", href: "/logins")
      expect(page).to have_button("Logout")
    end
  end
end
