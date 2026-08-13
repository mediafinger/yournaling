# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/current_team/search", type: :request do
  let!(:member) { Member.create!(team: team, user: user, roles: %w[owner]) }
  let(:team) { FactoryBot.create(:team) }
  let(:user) { FactoryBot.create(:user) }
  let(:location) { FactoryBot.create(:location, team: team, name: "Sunset Beach") }

  before do
    sign_in(user)
    switch_current_team(team)
  end

  describe "GET /current_team/new_search" do
    it "renders a successful response using the current_team_area layout" do
      get current_team_new_search_url
      expect(response).to be_successful
      expect(response.body).to include("current-team-area")
    end
  end

  describe "POST /current_team/search" do
    it "searches within current team and redirects to search results" do
      location

      post current_team_search_url, params: { query: "Sunset", klass_name: "Location" }

      expect(response).to redirect_to(%r{/current_team/new_search\?klass_name=Location&query=Sunset})
    end
  end
end
