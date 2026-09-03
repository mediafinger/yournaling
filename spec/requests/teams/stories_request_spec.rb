# frozen_string_literal: true

require "rails_helper"

RSpec.describe "teams/:team_id/stories", type: :request do
  let(:team) { FactoryBot.create(:team) }

  describe "GET /show" do
    it "renders a published story with its Markdown rendered" do
      story = FactoryBot.create(:story, team: team, name: "Open Story", content: "## Public\n\nA published chapter.",
        visibility: "published")
      get team_story_url(team, story)
      expect(response).to be_successful
      expect(response.body).to include("Open Story")
      expect(response.body).to include("<h2")
    end

    it "renders 404 when the story is internal" do
      story = FactoryBot.create(:story, team: team, visibility: "internal")
      get team_story_url(team, story)
      expect(response).to be_not_found
    end
  end
end
