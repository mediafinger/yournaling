# frozen_string_literal: true

require "rails_helper"

RSpec.describe "teams/:team_id/thoughts", type: :request do
  let(:team) { FactoryBot.create(:team) }

  describe "GET /show" do
    it "renders a successful response when thought is published" do
      thought = FactoryBot.create(:thought, team: team, text: "Open philosophy note", visibility: "published")
      get team_thought_url(team, thought)
      expect(response).to be_successful
      expect(response.body).to include("Open philosophy note")
    end

    it "renders 404 when thought is internal" do
      thought = FactoryBot.create(:thought, team: team, text: "Private team note", visibility: "internal")
      get team_thought_url(team, thought)
      expect(response).to be_not_found
    end
  end
end
