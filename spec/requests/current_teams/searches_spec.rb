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

    it "renders search results when query is provided and at least 3 characters" do
      location

      get current_team_new_search_url, params: { query: "Sunset", klass_name: "Location" }
      expect(response).to be_successful
      expect(response.body).to include("Sunset Beach")
    end

    it "renders an empty notice when search yields no results" do
      get current_team_new_search_url, params: { query: "Nonexistent", klass_name: "Location" }
      expect(response).to be_successful
      expect(response.body).to include("No results found.")
    end

    it "does not render search results when query is shorter than 3 characters" do
      location

      get current_team_new_search_url, params: { query: "Su", klass_name: "Location" }
      expect(response).to be_successful
      expect(response.body).not_to include("Sunset Beach")
    end
  end

  describe "POST /current_team/search" do
    it "searches within current team and redirects to search results" do
      location

      post current_team_search_url, params: { query: "Sunset", klass_name: "Location" }

      expect(response).to redirect_to(%r{/current_team/new_search\?klass_name=Location&query=Sunset})
    end

    it "redirects without query when query is shorter than 3 characters" do
      post current_team_search_url, params: { query: "Su", klass_name: "Memory" }

      expect(response).to redirect_to(current_team_new_search_url(klass_name: "Memory"))
    end
  end
end
