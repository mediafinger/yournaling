# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Teams::Pages (public team home)", type: :request do
  let(:team) { FactoryBot.create(:team, name: "Alpine Explorers") }
  let(:other_team) { FactoryBot.create(:team, name: "Desert Wanderers") }

  describe "GET /teams/:team_id" do
    it "renders the team's published stories and memories, scoped to that team" do
      FactoryBot.create(:chronicle, team: team, name: "Mont Blanc Summit", visibility: "published")
      FactoryBot.create(:memory, team: team, memo: "Sunrise at the refuge", visibility: "published")
      FactoryBot.create(:chronicle, team: team, name: "Secret Route Draft", visibility: "draft")
      FactoryBot.create(:chronicle, team: other_team, name: "Sahara Crossing", visibility: "published")

      get team_home_path(team_id: team.to_param)

      expect(response).to be_successful
      expect(response.body).to include("Mont Blanc Summit")
      expect(response.body).to include("Sunrise at the refuge")
      expect(response.body).not_to include("Secret Route Draft") # not published
      expect(response.body).not_to include("Sahara Crossing") # other team
    end

    it "shows an empty state when the team has published nothing" do
      get team_home_path(team_id: team.to_param)

      expect(response).to be_successful
      expect(response.body).to include("Nothing published yet")
    end
  end
end
