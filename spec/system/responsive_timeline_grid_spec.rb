# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Responsive Timeline Grid & Card Redesign", type: :system do
  include ActionView::RecordIdentifier

  let(:team) { FactoryBot.create(:team, name: "Globetrotters") }
  let(:user) { FactoryBot.create(:user, name: "Charlie Explorer", email: "charlie@example.com") }
  let!(:member) { Member.create!(team: team, user: user, roles: %w[owner]) }

  let!(:chronicle) do
    FactoryBot.create(
      :chronicle,
      team: team,
      name: "Alpine Expedition 2026",
      notice: "A thrilling journey through the Alps that spans over twenty characters long.",
      visibility: "published"
    )
  end

  let!(:memory) do
    FactoryBot.create(
      :memory,
      team: team,
      memo: "Sunset over Lake Geneva in the warm summer evening.",
      visibility: "published"
    )
  end

  let!(:thought) do
    FactoryBot.create(
      :thought,
      team: team,
      text: "The mountains are calling and I must go right now.",
      visibility: "published"
    )
  end

  let!(:location) do
    FactoryBot.create(
      :location,
      team: team,
      name: "Matterhorn Base Camp",
      visibility: "published"
    )
  end

  let!(:weblink) do
    FactoryBot.create(
      :weblink,
      team: team,
      name: "Swiss Alpine Club",
      url: "https://www.sac-cas.ch",
      visibility: "published"
    )
  end

  describe "Browse Mode Timeline Grid & Cards" do
    it "renders timeline items inside a responsive .ex-record-grid with card styling" do
      visit root_url

      expect(page).to have_css(".ex-record-grid")
      expect(page).to have_css("article.ex-chronicle-card[id='#{dom_id(chronicle)}']")
      expect(page).to have_css("article.ex-memory-card[id='#{dom_id(memory)}']")

      within("article.ex-chronicle-card") do
        expect(page).to have_css(".ex-eyebrow", text: /Chronicle/)
        expect(page).to have_text("Alpine Expedition 2026")
      end

      within("article.ex-memory-card") do
        expect(page).to have_css(".ex-badge", text: /Memory/)
        expect(page).to have_text("Sunset over Lake Geneva")
      end
    end

    it "styles thoughts as blockquote quotes, locations as chips, and weblinks as chips" do
      memory.update!(thought: thought, location: location, weblink: weblink)

      visit root_url

      within("article.ex-memory-card") do
        expect(page).to have_css("blockquote.thought-quote", text: "The mountains are calling and I must go right now.")
        expect(page).to have_css("a.ex-tag[href='#{weblink.url}']", text: /Swiss Alpine Club/)
        expect(page).to have_css("span.ex-tag", text: /Matterhorn Base Camp/)
      end
    end
  end

  describe "Manage Mode Timeline Grid & Cards" do
    it "renders manage mode artefacts in .ex-record-grid with cards" do
      visit_sign_in(user)
      visit_switch_current_team(team)
      visit current_team_home_url

      expect(page).to have_css(".ex-record-grid")
      expect(page).to have_css("article.ex-chronicle-card")
      expect(page).to have_css("article.ex-memory-card")
    end
  end
end
