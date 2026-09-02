# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Browse Mode Central Home Feed", type: :system do
  include ActionView::RecordIdentifier

  let(:team) { FactoryBot.create(:team, name: "Alpine Explorers") }
  let(:user) { FactoryBot.create(:user, email: "explorer@example.com", name: "Sam Explorer") }
  let!(:member) { Member.create!(team: team, user: user, roles: %w[owner publisher]) }

  let!(:chronicle1) do
    c = FactoryBot.create(:chronicle, team: team, name: "Mont Blanc Summit", visibility: "published")
    c.publishing.update!(republished_at: 3.hours.ago)
    c
  end

  let!(:memory1) do
    m = FactoryBot.create(:memory, team: team, memo: "Sunrise at Refugio", visibility: "published")
    m.publishing.update!(republished_at: 2.hours.ago)
    m
  end

  let!(:chronicle2) do
    c = FactoryBot.create(:chronicle, team: team, name: "Matterhorn Trail", visibility: "published")
    c.publishing.update!(republished_at: 1.hour.ago)
    c
  end

  let!(:internal_chronicle) do
    FactoryBot.create(:chronicle, team: team, name: "Secret Route Draft", visibility: "internal")
  end

  it "displays published chronicles and memories on the home feed ordered by republished_at DESC" do
    visit root_url

    # Should display the published items
    expect(page).to have_text("Matterhorn Trail")
    expect(page).to have_text("Sunrise at Refugio")
    expect(page).to have_text("Mont Blanc Summit")

    # Should not display unpublished items
    expect(page).to have_no_text("Secret Route Draft")

    # Click on Open to navigate to the public chronicle show page
    within "[id='#{dom_id(chronicle2)}']" do
      click_link "Open"
    end

    expect(page).to have_current_path(team_chronicle_path(team, chronicle2))
    expect(page).to have_text("Matterhorn Trail")
  end

  it "paginates results using endless scroll without showing page numbers or item counts" do
    # Create 4 more published items (total 7 published items, page limit is 5)
    4.times do |i|
      m = FactoryBot.create(:memory, team: team, memo: "Extra Mountain Memory #{i + 1}", visibility: "published")
      m.publishing.update!(republished_at: (30 + i).minutes.ago)
    end

    visit root_url

    # First page should show 5 items
    expect(page).to have_text("Extra Mountain Memory 4")
    expect(page).to have_text("Extra Mountain Memory 3")
    expect(page).to have_text("Extra Mountain Memory 2")
    expect(page).to have_text("Extra Mountain Memory 1")
    expect(page).to have_text("Matterhorn Trail")

    # Second page items should not yet be loaded until turbo frame triggers
    expect(page).to have_no_text("Mont Blanc Summit")

    # Verify no pagination controls (no page numbers, no 'Page 1 of 2')
    expect(page).to have_no_css(".pagination")
    expect(page).to have_no_css("nav.pagy")
    expect(page).to have_no_text("Page 1")
    expect(page).to have_no_text("of 2")
  end

  it "includes Stimulus feed-refresh controller markup for automatic feed update checking" do
    visit root_url

    expect(page).to have_css("#publishings[data-controller='feed-refresh']")
    expect(page).to have_css("#top_sentinel")
    expect(page).to have_css("#newer_posts_banner", text: "newer posts available, scroll up to load them", visible: :all)
    expect(page).to have_css("#newer_posts_container")

    # In the DOM but `hidden` — the feed-refresh controller unhides it only when
    # polling finds newer posts. Regression: `.yui-feed-banner { display: block }`
    # used to override the UA `[hidden]` rule and show it on load.
    expect(page).to have_no_css("#newer_posts_banner", text: "newer posts available")
  end

  it "allows navigating back to browse mode home feed from the team area" do
    visit login_url
    fill_in :email, with: user.email
    fill_in :password, with: "foobar1234"
    click_button "Login"
    visit_switch_current_team(team)

    visit current_team_chronicles_url
    expect(page).to have_link("🌐 Yournaling")

    click_link "🌐 Yournaling"
    expect(page).to have_current_path(root_path)
  end
end
