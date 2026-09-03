# frozen_string_literal: true

require "rails_helper"

RSpec.describe "teams/:team_id/members", type: :request do
  let(:team) { FactoryBot.create(:team) }

  describe "GET /index" do
    it "lays the cards out in the shared responsive record grid" do
      FactoryBot.create(:member, team: team)

      get team_members_url(team)

      expect(response).to be_successful
      expect(response.body).to include("yui-record-grid")
    end
  end
end
