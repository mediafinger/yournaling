# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Pages (Home Feed in Browse Mode)", type: :request do
  let(:team) { FactoryBot.create(:team, name: "Travelers Club") }

  describe "GET /" do
    it "renders a successful response" do
      get root_url
      expect(response).to be_successful
    end

    context "with published and unpublished content" do
      let!(:chronicle1) do
        c = FactoryBot.create(:chronicle, team: team, name: "Alps Expedition", visibility: "published")
        c.publishing.update!(republished_at: 6.hours.ago)
        c
      end
      let!(:memory1) do
        m = FactoryBot.create(:memory, team: team, memo: "Summit Sunrise Memo", visibility: "published")
        m.publishing.update!(republished_at: 5.hours.ago)
        m
      end
      let!(:chronicle2) do
        c = FactoryBot.create(:chronicle, team: team, name: "Sahara Crossing", visibility: "published")
        c.publishing.update!(republished_at: 4.hours.ago)
        c
      end
      let!(:memory2) do
        m = FactoryBot.create(:memory, team: team, memo: "Oasis Campfire Memo", visibility: "published")
        m.publishing.update!(republished_at: 3.hours.ago)
        m
      end
      let!(:chronicle3) do
        c = FactoryBot.create(:chronicle, team: team, name: "Nordic Fjord Trek", visibility: "published")
        c.publishing.update!(republished_at: 2.hours.ago)
        c
      end
      let!(:memory3) do
        m = FactoryBot.create(:memory, team: team, memo: "Glacier Hike Memo", visibility: "published")
        m.publishing.update!(republished_at: 1.hour.ago)
        m
      end

      it "displays the 5 latest published items on page 1 ordered by republished_at DESC" do
        get root_url

        expect(response).to be_successful
        expect(response.body).to include("Glacier Hike Memo")
        expect(response.body).to include("Nordic Fjord Trek")
        expect(response.body).to include("Oasis Campfire Memo")
        expect(response.body).to include("Sahara Crossing")
        expect(response.body).to include("Summit Sunrise Memo")
        expect(response.body).not_to include("Alps Expedition")
        expect(response.body.index("Glacier Hike Memo")).to be < response.body.index("Summit Sunrise Memo")
      end

      it "renders endless scroll turbo frames for page 1 and page 2" do
        get root_url

        expect(response.body).to include("id=\"publishings_page_1\"")
        expect(response.body).to include("id=\"publishings_page_2\"")
        expect(response.body).to include("loading=\"lazy\"")
      end

      it "displays the next page of publishings when requesting page 2" do
        get root_url(page: 2)

        expect(response).to be_successful
        expect(response.body).to include("id=\"publishings_page_2\"")
        expect(response.body).to include("Alps Expedition")
        expect(response.body).not_to include("Glacier Hike Memo")
      end

      it "excludes unpublished posts" do
        FactoryBot.create(:chronicle, team: team, name: "Secret Cave Exploration", visibility: "internal")
        FactoryBot.create(:memory, team: team, memo: "Private Draft Memo", visibility: "draft")

        get root_url

        expect(response.body).not_to include("Secret Cave Exploration")
        expect(response.body).not_to include("Private Draft Memo")
      end

      it "renders feed refresh controller markup and banner" do
        get root_url

        expect(response.body).to include("data-controller=\"feed-refresh\"")
        expect(response.body).to include("newer posts available, scroll up to load them")
      end
    end
  end

  describe "GET /check_newer" do
    let!(:memory) do
      m = FactoryBot.create(:memory, team: team, memo: "Old Memo", visibility: "published")
      m.publishing.update!(republished_at: 2.hours.ago)
      m
    end

    it "returns count 0 when no newer publishings exist" do
      get check_newer_pages_url, params: { since: 1.hour.ago.iso8601(6) }

      expect(response).to be_successful
      json = JSON.parse(response.body)
      expect(json["count"]).to eq(0)
      expect(json["latest_republished_at"]).to be_nil
    end

    it "returns count and timestamp when newer publishings exist" do
      new_chronicle = FactoryBot.create(:chronicle, team: team, name: "Fresh Chronicle", visibility: "published")
      new_chronicle.publishing.update!(republished_at: 10.minutes.ago)

      get check_newer_pages_url, params: { since: 1.hour.ago.iso8601(6) }

      expect(response).to be_successful
      json = JSON.parse(response.body)
      expect(json["count"]).to eq(1)
      expect(json["latest_republished_at"]).to eq(new_chronicle.publishing.republished_at.iso8601(6))
    end
  end

  describe "GET /newer" do
    it "renders the newly published items since the given timestamp" do
      new_chronicle = FactoryBot.create(:chronicle, team: team, name: "Fresh Chronicle", visibility: "published")
      new_chronicle.publishing.update!(republished_at: 10.minutes.ago)

      get newer_pages_url, params: { since: 1.hour.ago.iso8601(6) }

      expect(response).to be_successful
      expect(response.body).to include("Fresh Chronicle")
      expect(response.body).to include(new_chronicle.publishing.republished_at.iso8601(6))
    end
  end
end
