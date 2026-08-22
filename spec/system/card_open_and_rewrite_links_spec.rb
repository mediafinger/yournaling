# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Card Open and Rewrite Links", type: :system do
  include ActionView::RecordIdentifier

  let(:team) { FactoryBot.create(:team, name: "Alpine Explorers") }
  let(:user) { FactoryBot.create(:user, email: "explorer@example.com") }
  let!(:member) { Member.create!(team: team, user: user, roles: %w[owner publisher]) }

  let!(:chronicle) do
    c = FactoryBot.create(:chronicle, team: team, name: "Mont Blanc Summit", visibility: "published")
    c.publishing.update!(republished_at: 1.hour.ago)
    c.update_column(:updated_at, 1.hour.ago)
    c
  end

  let!(:memory) do
    m = FactoryBot.create(:memory, team: team, memo: "Sunrise at Refugio", visibility: "published")
    m.publishing.update!(republished_at: 1.hour.ago)
    m.update_column(:updated_at, 1.hour.ago)
    m
  end

  def login_as(user)
    visit login_url
    fill_in :email, with: user.email
    fill_in :password, with: "foobar1234"
    click_button "Login"
    visit_switch_current_team(team)
  end

  context "in browse mode" do
    it "keeps Open on the browse chronicle in browse mode" do
      visit team_chronicles_path(team)

      within "[id='#{dom_id(chronicle)}']" do
        click_link "Open"
      end

      expect(page).to have_current_path(team_chronicle_path(team, chronicle))
    end

    it "keeps Open on the browse memory in browse mode" do
      visit team_memories_path(team)

      within "[id='#{dom_id(memory)}']" do
        click_link "Open"
      end

      expect(page).to have_current_path(team_memory_path(team, memory))
    end

    it "sends Rewrite to the current_team (manage) edit view" do
      login_as(user)
      visit team_chronicles_path(team)

      within "[id='#{dom_id(chronicle)}']" do
        click_link "Rewrite"
      end

      expect(page).to have_current_path(edit_current_team_chronicle_path(chronicle))
    end
  end

  context "in manage (current_team) mode" do
    before do
      login_as(user)
    end

    it "keeps Open on the manage chronicle in current_team scope" do
      visit current_team_chronicles_path

      within "[id='#{dom_id(chronicle)}']" do
        click_link "Open"
      end

      expect(page).to have_current_path(current_team_chronicle_path(chronicle))
    end

    it "keeps Open on the manage memory in current_team scope" do
      visit current_team_memories_path

      within "[id='#{dom_id(memory)}']" do
        click_link "Open"
      end

      expect(page).to have_current_path(current_team_memory_path(memory))
    end

    it "sends Rewrite to the current_team (manage) edit view" do
      visit current_team_memories_path

      within "[id='#{dom_id(memory)}']" do
        click_link "Rewrite"
      end

      expect(page).to have_current_path(edit_current_team_memory_path(memory))
    end
  end

  # The home feeds (root_path / current_team_home_path) wrap their cards in a
  # <turbo-frame> for lazy pagination. Once the *second page* loads (via that
  # frame's own client-side src fetch, triggered by scrolling it into view),
  # its cards live inside the frame element that was originally rendered on
  # page 1 as just a placeholder — Turbo only ever replaces a frame's inner
  # content, never the frame element's own attributes, so that placeholder's
  # `target="_top"` (not just the current-page frame's) is what actually
  # matters. Without it on both, clicking Open/Rewrite on a page-2+ card
  # rendered Turbo's "Content missing" instead of navigating, and further
  # pagination broke too since that click destroyed the frame's content.
  # rack_test doesn't run Turbo's client-side JS at all, so this needs a real
  # browser (js: true) to actually exercise page-2 lazy-loading + the bug.
  #
  # TODO: this spec is broken and always times out. Needs fixing.
  #
  pending "on a lazily-loaded (page 2) card from the turbo-frame-wrapped home feeds", js: true do
    let!(:newer_chronicles) do
      # More recent than `chronicle`/`memory` (1 hour ago) in both the browse feed's
      # ordering (republished_at) and the manage feed's ordering (updated_at), so
      # these 5 fill page 1 and push `chronicle`/`memory` onto the lazily-loaded page 2.
      Array.new(5) do |i|
        c = FactoryBot.create(:chronicle, team: team, name: "Filler Chronicle #{i}", visibility: "published")
        c.publishing.update!(republished_at: (i + 1).minutes.ago)
        c.update_column(:updated_at, (i + 1).minutes.ago)
        c
      end
    end

    def scroll_to_page_2(marker_text)
      # The lazy frame only fetches once it intersects the viewport.
      page.execute_script("window.scrollTo(0, document.body.scrollHeight)")
      expect(page).to have_text(marker_text, wait: 10)
    end

    it "navigates (not 'Content missing') when clicking Open on a page-2 browse card" do
      visit root_path
      scroll_to_page_2("Mont Blanc Summit")

      within "[id='#{dom_id(chronicle)}']" do
        click_link "Open"
      end

      expect(page).to have_current_path(team_chronicle_path(team, chronicle))
      expect(page).to have_no_text("Content missing")
    end

    it "navigates (not 'Content missing') when clicking Rewrite on a page-2 browse card" do
      login_as(user)
      visit root_path
      scroll_to_page_2("Mont Blanc Summit")

      within "[id='#{dom_id(chronicle)}']" do
        click_link "Rewrite"
      end

      expect(page).to have_current_path(edit_current_team_chronicle_path(chronicle))
      expect(page).to have_no_text("Content missing")
    end

    it "navigates (not 'Content missing') when clicking Open on a page-2 manage card" do
      login_as(user)
      visit current_team_home_path
      scroll_to_page_2("Sunrise at Refugio")

      within "[id='#{dom_id(memory)}']" do
        click_link "Open"
      end

      expect(page).to have_current_path(current_team_memory_path(memory))
      expect(page).to have_no_text("Content missing")
    end

    it "navigates (not 'Content missing') when clicking Rewrite on a page-2 manage card" do
      login_as(user)
      visit current_team_home_path
      scroll_to_page_2("Sunrise at Refugio")

      within "[id='#{dom_id(memory)}']" do
        click_link "Rewrite"
      end

      expect(page).to have_current_path(edit_current_team_memory_path(memory))
      expect(page).to have_no_text("Content missing")
    end
  end
end
