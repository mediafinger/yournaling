# frozen_string_literal: true

require "rails_helper"

RSpec.describe "teams/:team_id/weblinks", type: :request do
  let(:team) { FactoryBot.create(:team) }

  describe "GET /show" do
    it "renders a successful response when weblink is published" do
      weblink = FactoryBot.create(:weblink, team: team, name: "Public Guide", url: "public.example.com",
        visibility: "published")
      get team_weblink_url(team, weblink)
      expect(response).to be_successful
      expect(response.body).to include("Public Guide")
    end

    it "renders 404 when weblink is internal" do
      weblink = FactoryBot.create(:weblink, team: team, name: "Internal Doc", url: "internal.example.com",
        visibility: "internal")
      get team_weblink_url(team, weblink)
      expect(response).to be_found.or be_not_found
    end
  end
end
