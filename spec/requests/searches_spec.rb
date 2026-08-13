# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/search", type: :request do
  let(:team) { FactoryBot.create(:team) }
  let(:location) { FactoryBot.create(:location, team: team, name: "Sunset Beach") }

  describe "GET /search" do
    it "renders a successful response" do
      get new_search_url
      expect(response).to be_successful
    end

    it "renders search results when query is provided and at least 3 characters" do
      location

      get new_search_url, params: { query: "Sunset", klass_name: "Location" }
      expect(response).to be_successful
      expect(response.body).to include("Sunset Beach")
    end

    it "does not render search results when query is shorter than 3 characters" do
      location

      get new_search_url, params: { query: "Su", klass_name: "Location" }
      expect(response).to be_successful
      expect(response.body).not_to include("Sunset Beach")
    end
  end

  describe "POST /search" do
    it "searches across records and redirects to search results" do
      location

      post search_url, params: { query: "Sunset", klass_name: "Location" }

      expect(response).to redirect_to(%r{/search\?klass_name=Location&query=Sunset})
    end

    it "searches for teams and redirects to search results" do
      team

      post search_url, params: { query: team.name, klass_name: "Team" }

      expect(response).to redirect_to(%r{/search\?klass_name=Team&query=#{Regexp.escape(CGI.escape(team.name))}})
    end

    it "redirects without query when query is shorter than 3 characters" do
      post search_url, params: { query: "Su", klass_name: "Team" }

      expect(response).to redirect_to(new_search_url(klass_name: "Team"))
    end
  end
end
