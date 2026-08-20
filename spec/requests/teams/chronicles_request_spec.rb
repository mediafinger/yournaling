# frozen_string_literal: true

require "rails_helper"

RSpec.describe "teams/:team_id/chronicles", type: :request do
  let(:team) { FactoryBot.create(:team) }
  let(:valid_attributes) do
    {
      name: "Alpine Odyssey",
      notice: "A journey through the Swiss Alps crossing peaks and valleys.",
      start_date: Time.current,
      team: team,
      visibility: "published",
    }
  end

  describe "GET /show" do
    it "renders a successful response for a published chronicle" do
      chronicle = Chronicle.create!(valid_attributes)
      get team_chronicle_url(team, chronicle)
      expect(response).to be_successful
    end

    it "renders a successful response displaying all associated entries in position order after the notice" do
      chronicle = Chronicle.create!(valid_attributes)
      picture = FactoryBot.create(:picture, team: team, name: "Beach View")
      thought = FactoryBot.create(:thought, team: team, text: "Sunset at the campsite")
      location = FactoryBot.create(:location, team: team, name: "Ferlandina")
      weblink = FactoryBot.create(:weblink, team: team, name: "Camp Map", url: "https://example.com/map")

      FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: picture, position: 1)
      FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: thought, position: 2)
      FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: location, position: 3)
      FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: weblink, position: 4)

      get team_chronicle_url(team, chronicle)
      expect(response).to be_successful

      notice_index = response.body.index(chronicle.notice)
      entry1_index = response.body.index("Beach View")
      entry2_index = response.body.index("Sunset at the campsite")
      entry3_index = response.body.index("Ferlandina")
      entry4_index = response.body.index("Camp Map")

      expect(notice_index).to be < entry1_index
      expect(entry1_index).to be < entry2_index
      expect(entry2_index).to be < entry3_index
      expect(entry3_index).to be < entry4_index
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
      expect(response.body).to include("Sierra Nevada Sunset")

      get team_picture_url(team, picture)
      expect(response).to be_successful

      get team_picture_only_url(team, picture)
      expect(response).to be_successful
    end
  end
end
