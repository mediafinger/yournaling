# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Card Actions and Empty States", type: :system do
  let(:team) { FactoryBot.create(:team, name: "Alpine Explorers") }
  let(:user) { FactoryBot.create(:user) }
  let!(:member) { Member.create!(team: team, user: user, roles: %w[owner publisher]) }

  def login_as(user)
    visit login_url
    fill_in :email, with: user.email
    fill_in :password, with: "foobar1234"
    click_button "Login"
    visit_switch_current_team(team)
  end

  context "when browsing empty timeline" do
    it "displays friendly empty state on home page when no posts are published" do
      visit root_url

      expect(page).to have_text("No published stories or memories yet")
    end
  end

  context "when managing team with no memories" do
    before do
      login_as(user)
    end

    it "displays friendly empty state with CTA button on current_team memories index" do
      visit current_team_memories_path

      expect(page).to have_text("No memories recorded yet")
      expect(page).to have_link("Create your first memory", href: new_current_team_memory_path)
    end

    it "displays friendly empty state with CTA button on current_team chronicles index" do
      visit current_team_chronicles_path

      expect(page).to have_text("No chronicles written yet")
      expect(page).to have_link("Start your first chronicle", href: new_current_team_chronicle_path)
    end
  end
end
