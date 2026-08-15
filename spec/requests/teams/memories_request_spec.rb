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
    it "renders a successful response for published memories" do
      memory = Memory.create!(valid_attributes)
      get team_memory_url(team, memory)
      expect(response).to be_successful
      expect(response.body).to include(memory.memo)
      expect(response.body).to include("Sunset Beach")
    end

    it "renders 404 when memory is internal" do
      memory = Memory.create!(valid_attributes.merge(visibility: "internal"))
      get team_memory_url(team, memory)
      expect(response).to be_not_found
    end
  end
end
