# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Current Team Manage Section Timeline", type: :system do
  let(:team) { FactoryBot.create(:team, name: "Voyager Team") }
  let(:other_team) { FactoryBot.create(:team, name: "Other Team") }
  let(:owner_user) { FactoryBot.create(:user, email: "owner@example.com", name: "Alice Owner") }
  let(:editor_user) { FactoryBot.create(:user, email: "editor@example.com", name: "Bob Editor") }
  let(:publisher_user) { FactoryBot.create(:user, email: "publisher@example.com", name: "Charlie Publisher") }

  let!(:owner_member) { Member.create!(team: team, user: owner_user, roles: %w[owner]) }
  let!(:editor_member) { Member.create!(team: team, user: editor_user, roles: %w[editor]) }
  let!(:publisher_member) { Member.create!(team: team, user: publisher_user, roles: %w[publisher]) }

  let!(:draft_chronicle) do
    FactoryBot.create(:chronicle, team: team, name: "Draft Amazon Trek", visibility: "draft", updated_at: 1.hour.ago)
  end
  let!(:internal_memory) do
    FactoryBot.create(:memory, team: team, memo: "Internal Basecamp Memo", visibility: "internal", updated_at: 2.hours.ago)
  end
  let!(:published_picture) do
    FactoryBot.create(:picture, team: team, name: "Published Glacier Pic", visibility: "published", updated_at: 3.hours.ago)
  end
  let!(:archived_thought) do
    FactoryBot.create(:thought, team: team, text: "Archived Expedition Idea", visibility: "archived",
      updated_at: 4.hours.ago)
  end
  let!(:other_team_chronicle) do
    FactoryBot.create(:chronicle, team: other_team, name: "Alien Expedition", visibility: "published")
  end

  def login_as(user)
    visit login_url
    fill_in :email, with: user.email
    fill_in :password, with: "foobar1234"
    click_button "Login"
    visit_switch_current_team(team)
  end

  it "renders all artefacts across all visibilities for an owner, excluding other teams" do
    login_as(owner_user)
    visit current_team_home_url

    expect(page).to have_text("Draft Amazon Trek")
    expect(page).to have_text("Internal Basecamp Memo")
    expect(page).to have_text("Published Glacier Pic")
    expect(page).to have_text("Archived Expedition Idea")
    expect(page).to have_no_text("Alien Expedition")

    expect(page).to have_css("div[data-controller='feed-refresh']")
    expect(page).to have_css("#newer_posts_banner", text: "newer posts available, scroll up to load them",
      visible: :all)
  end

  it "excludes archived artefacts for an editor" do
    login_as(editor_user)
    visit current_team_home_url

    expect(page).to have_text("Draft Amazon Trek")
    expect(page).to have_text("Internal Basecamp Memo")
    expect(page).to have_text("Published Glacier Pic")
    expect(page).to have_no_text("Archived Expedition Idea")
  end

  it "excludes draft artefacts for a publisher" do
    login_as(publisher_user)
    visit current_team_home_url

    expect(page).to have_text("Internal Basecamp Memo")
    expect(page).to have_text("Published Glacier Pic")
    expect(page).to have_text("Archived Expedition Idea")
    expect(page).to have_no_text("Draft Amazon Trek")
  end

  it "paginates timeline artefacts with endless scroll turbo frames without page counters" do
    login_as(owner_user)

    # Add 4 more artefacts to exceed AppConf.items_per_page (5 items)
    4.times do |i|
      FactoryBot.create(:thought, team: team, text: "Extra Note #{i + 1}", visibility: "internal",
        updated_at: (i + 5).hours.ago)
    end

    visit current_team_home_url

    expect(page).to have_text("Extra Note 4")
    expect(page).to have_text("Extra Note 1")
    expect(page).to have_css("turbo-frame#team_artefacts_page_2[loading='lazy']")
    expect(page).to have_no_text("Page 1")
    expect(page).to have_no_text("Showing 1-5")
  end
end
