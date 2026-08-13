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
  end

  describe "POST /search" do
    it "searches across records and redirects to search results" do
      location

      post search_url, params: { query: "Sunset", klass_name: "Location" }

      expect(response).to redirect_to(%r{/search\?klass_name=Location&query=Sunset})
    end
  end
end
