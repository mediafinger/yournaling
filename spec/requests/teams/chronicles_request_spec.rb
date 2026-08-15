# frozen_string_literal: true

require "rails_helper"

RSpec.describe "teams/:team_id/chronicles", type: :request do
  let(:team) { FactoryBot.create(:team) }
  let(:valid_attributes) do
    {
      team: team,
      name: "Roadtrip through Andalusia",
      notice: "A detailed chronicle of our roadtrip across the southern coast of Spain.",
      start_date: Date.current,
      end_date: Date.current + 7.days,
      visibility: "published",
    }
  end

  describe "GET /index" do
    it "renders a successful response for published chronicles" do
      Chronicle.create!(valid_attributes)
      get team_chronicles_url(team)
      expect(response).to be_successful
    end

    it "only includes published chronicles in the list" do
      published = Chronicle.create!(valid_attributes)
      internal = Chronicle.create!(valid_attributes.merge(name: "Internal Secrets", visibility: "internal"))

      get team_chronicles_url(team)
      expect(response).to be_successful
      expect(response.body).to include(published.name)
      expect(response.body).not_to include(internal.name)
    end
  end

  describe "GET /show" do
    it "renders a successful response when the chronicle is published" do
      chronicle = Chronicle.create!(valid_attributes)
      get team_chronicle_url(team, chronicle)
      expect(response).to be_successful
    end

    it "renders a 404 when the chronicle is internal" do
      chronicle = Chronicle.create!(valid_attributes.merge(visibility: "internal"))
      get team_chronicle_url(team, chronicle)
      expect(response).to be_not_found
    end

    it "renders a 404 when the chronicle is draft" do
      chronicle = Chronicle.create!(valid_attributes.merge(visibility: "draft"))
      get team_chronicle_url(team, chronicle)
      expect(response).to be_not_found
    end
  end
end
