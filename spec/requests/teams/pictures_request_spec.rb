# frozen_string_literal: true

require "rails_helper"

RSpec.describe "teams/:team_id/pictures", type: :request do
  let(:team) { FactoryBot.create(:team) }

  describe "GET /show" do
    it "renders a successful response when picture is published" do
      picture = FactoryBot.create(:picture, team: team, name: "Published Scenery", visibility: "published")
      get team_picture_url(team, picture)
      expect(response).to be_successful
      expect(response.body).to include("Published Scenery")
    end

    it "renders 404 when picture is internal" do
      picture = FactoryBot.create(:picture, team: team, name: "Secret Snapshot", visibility: "internal")
      get team_picture_url(team, picture)
      expect(response).to be_not_found
    end
  end
end
