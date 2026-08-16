# frozen_string_literal: true

require "rails_helper"

RSpec.describe "teams/:team_id/locations", type: :request do
  let(:team) { FactoryBot.create(:team) }

  describe "GET /show" do
    it "renders a successful response when location is published" do
      location = FactoryBot.create(:location, team: team, name: "Public Lookout", visibility: "published")
      get team_location_url(team, location)
      expect(response).to be_successful
      expect(response.body).to include("Public Lookout")
    end

    it "renders 404 when location is internal" do
      location = FactoryBot.create(:location, team: team, name: "Secret Base", visibility: "internal")
      get team_location_url(team, location)
      expect(response).to be_not_found
    end
  end
end
