# frozen_string_literal: true

require "rails_helper"

RSpec.describe "CurrentTeams::Pages (Manage Timeline)", type: :request do
  let(:team) { FactoryBot.create(:team, name: "Alpha Squad") }
  let(:other_team) { FactoryBot.create(:team, name: "Beta Squad") }
  let(:user) { FactoryBot.create(:user) }
  let!(:member) { Member.create!(team: team, user: user, roles: member_roles) }
  let(:member_roles) { %w[owner] }

  before do
    sign_in(user)
    switch_current_team(team)
  end

  describe "GET /current_team" do
    let!(:draft_chronicle) {
      FactoryBot.create(:chronicle, team: team, name: "Secret Draft Chronicle", visibility: "draft", updated_at: 1.hour.ago)
    }
    let!(:published_memory) {
      FactoryBot.create(:memory, team: team, memo: "Public Mountain Memory", visibility: "published",
        updated_at: 2.hours.ago)
    }
    let!(:archived_thought) {
      FactoryBot.create(:thought, team: team, text: "Old Archived Thought", visibility: "archived", updated_at: 3.hours.ago)
    }
    let!(:other_team_chronicle) {
      FactoryBot.create(:chronicle, team: other_team, name: "Other Team Post", visibility: "published")
    }

    context "when logged in as an owner" do
      let(:member_roles) { %w[owner] }

      it "renders all artefacts including draft, published, and archived, excluding other teams" do
        get current_team_home_url

        expect(response).to be_successful
        expect(response.body).to include("Secret Draft Chronicle")
        expect(response.body).to include("Public Mountain Memory")
        expect(response.body).to include("Old Archived Thought")
        expect(response.body).not_to include("Other Team Post")
      end

      it "renders feed refresh controller markup and banner" do
        get current_team_home_url

        expect(response.body).to include("data-controller=\"feed-refresh\"")
        expect(response.body).to include("newer posts available, scroll up to load them")
        expect(response.body).to include("id=\"team_artefacts_page_1\"")
      end

      it "marks the pagination frames with target=_top so card links always break out to a full page " \
         "navigation instead of Turbo trying (and failing) to load them into the pagination frame" do
        # See the matching regression test in spec/requests/pages_request_spec.rb for why both the
        # current-page frame AND the next-page lazy placeholder frame need target=_top.
        12.times { |i| FactoryBot.create(:memory, team: team, memo: "Extra Memory #{i}") }

        get current_team_home_url

        expect(response.body)
          .to match(/<turbo-frame\b(?=[^>]*\bid="team_artefacts_page_1")(?=[^>]*\btarget="_top")[^>]*>/)
        expect(response.body)
          .to match(/<turbo-frame\b(?=[^>]*\bid="team_artefacts_page_2")(?=[^>]*\btarget="_top")[^>]*>/)

        get current_team_home_url(page: 2)

        expect(response.body)
          .to match(/<turbo-frame\b(?=[^>]*\bid="team_artefacts_page_2")(?=[^>]*\btarget="_top")[^>]*>/)
      end
    end

    context "when logged in as an editor" do
      let(:member_roles) { %w[editor] }

      it "renders draft and published items but excludes archived items" do
        get current_team_home_url

        expect(response).to be_successful
        expect(response.body).to include("Secret Draft Chronicle")
        expect(response.body).to include("Public Mountain Memory")
        expect(response.body).not_to include("Old Archived Thought")
      end
    end

    context "when logged in as a publisher" do
      let(:member_roles) { %w[publisher] }

      it "renders published and archived items but excludes draft items" do
        get current_team_home_url

        expect(response).to be_successful
        expect(response.body).not_to include("Secret Draft Chronicle")
        expect(response.body).to include("Public Mountain Memory")
        expect(response.body).to include("Old Archived Thought")
      end
    end
  end

  describe "GET /current_team/check_newer" do
    let(:member_roles) { %w[owner] }

    it "returns count 0 when no items have been updated after timestamp" do
      get current_team_check_newer_pages_url, params: { since: Time.current.iso8601(6) }

      expect(response).to be_successful
      json = JSON.parse(response.body)
      expect(json["count"]).to eq(0)
      expect(json["latest_at"]).to be_nil
    end

    it "returns count and timestamp when newer updated items exist" do
      new_item = FactoryBot.create(:thought, team: team, text: "Brand New Note", visibility: "draft",
        updated_at: Time.current)

      get current_team_check_newer_pages_url, params: { since: 1.hour.ago.iso8601(6) }

      expect(response).to be_successful
      json = JSON.parse(response.body)
      expect(json["count"]).to be >= 1
      expect(json["latest_at"]).to eq(new_item.updated_at.iso8601(6))
    end
  end

  describe "GET /current_team/newer" do
    let(:member_roles) { %w[owner] }

    it "renders the HTML cards of artefacts updated since timestamp" do
      FactoryBot.create(:thought, team: team, text: "Newly Created Thought", visibility: "draft",
        updated_at: Time.current)

      get current_team_newer_pages_url, params: { since: 1.hour.ago.iso8601(6) }

      expect(response).to be_successful
      expect(response.body).to include("Newly Created Thought")
    end
  end
end
