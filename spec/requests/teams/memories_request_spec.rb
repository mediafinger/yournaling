# frozen_string_literal: true

require "rails_helper"

RSpec.describe "teams/:team_id/memories", type: :request do
  let(:team) { FactoryBot.create(:team) }
  let(:picture) { FactoryBot.create(:picture, team: team, name: "Sunset Beach", visibility: "published") }
  let(:valid_attributes) do
    {
      team: team,
      memo: "Memorable sunset with friends on the coast.",
      picture: picture,
      visibility: "published",
    }
  end

  describe "GET /index" do
    it "renders a successful response for published memories" do
      memory = Memory.create!(valid_attributes)
      get team_memories_url(team)
      expect(response).to be_successful
      expect(response.body).to include(memory.memo)
    end

    it "omits internal and draft memories from the list" do
      published = Memory.create!(valid_attributes)
      internal = Memory.create!(valid_attributes.merge(memo: "Secret internal memory", visibility: "internal"))

      get team_memories_url(team)
      expect(response).to be_successful
      expect(response.body).to include(published.memo)
      expect(response.body).not_to include(internal.memo)
    end
  end

  describe "GET /show" do
    it "renders a successful response for published memories with all attached insights (regression test)" do
      thought = FactoryBot.create(:thought, team: team, text: "Reflecting on nature", visibility: "published")
      location = FactoryBot.create(:location, team: team, name: "Cabo de Gata", visibility: "published")
      weblink = FactoryBot.create(:weblink, team: team, name: "Park Guide", url: "https://guide.com",
        visibility: "published")
      memory = Memory.create!(valid_attributes.merge(thought: thought, location: location, weblink: weblink))

      get team_memory_url(team, memory)
      expect(response).to be_successful
      expect(response.body).to include(memory.memo)
      expect(response.body).to include("Sunset Beach")
      expect(response.body).to include("Reflecting on nature")
      expect(response.body).to include("Cabo de Gata")
      expect(response.body).to include("Park Guide")
    end

    it "renders 404 when memory is internal" do
      memory = Memory.create!(valid_attributes.merge(visibility: "internal"))
      get team_memory_url(team, memory)
      expect(response).to be_not_found
    end
  end
end
