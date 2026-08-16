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
    it "renders a successful response for published chronicles displaying the first picture and omitting other entries" do
      chronicle = Chronicle.create!(valid_attributes)
      picture = FactoryBot.create(:picture, team: team, name: "Sierra Nevada Sunset")
      thought = FactoryBot.create(:thought, team: team, text: "Private camping observation")
      FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: picture, position: 1)
      FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: thought, position: 2)

      get team_chronicles_url(team)
      expect(response).to be_successful
      expect(response.body).to include("picture_#{picture.id}")
      expect(response.body).not_to include("Private camping observation")
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
    it "renders a successful response with all entries when the chronicle is published" do
      chronicle = Chronicle.create!(valid_attributes)
      picture = FactoryBot.create(:picture, team: team, name: "Sierra Nevada Sunset")
      thought = FactoryBot.create(:thought, team: team, text: "Private camping observation")
      FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: picture, position: 1)
      FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: thought, position: 2)

      get team_chronicle_url(team, chronicle)
      expect(response).to be_successful
      expect(response.body).to include("Sierra Nevada Sunset")
      expect(response.body).to include("Private camping observation")
    end

    it "displays all pictures when multiple pictures are attached to a published chronicle (regression test)" do
      chronicle = Chronicle.create!(valid_attributes)
      picture1 = FactoryBot.create(:picture, team: team, name: "Drone Coast Shot")
      picture2 = FactoryBot.create(:picture, team: team, name: "Ganesh Statue View")
      FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: picture1, position: 1)
      FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: picture2, position: 2)

      get team_chronicle_url(team, chronicle)
      expect(response).to be_successful
      expect(response.body).to include("Drone Coast Shot")
      expect(response.body).to include("Ganesh Statue View")
      expect(response.body.scan('article id="picture_').count).to eq(2)
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

    it "allows viewing attached internal picture and fullsize image when chronicle is published" do
      chronicle = Chronicle.create!(valid_attributes)
      picture = FactoryBot.create(:picture, team: team, name: "Sierra Nevada Sunset", visibility: "internal")
      FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: picture, position: 1)

      get team_chronicle_url(team, chronicle)
      expect(response).to be_successful
      expect(response.body).to include(team_picture_path(team, picture))

      get team_picture_url(team, picture)
      expect(response).to be_successful

      get team_picture_only_url(team, picture)
      expect(response).to be_successful
    end
  end
end
