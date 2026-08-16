# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/current_team/content_visibility", type: :request do
  let!(:member) { Member.create!(team: team, user: user, roles: %i[owner publisher]) }
  let(:user) { FactoryBot.create(:user) }
  let(:team) { FactoryBot.create(:team) }

  before do
    sign_in(user)
    switch_current_team(team)
  end

  describe "GET /content_visibility/:id" do
    it "renders the edit visibility form when accessed via /content_visibility/:id without /edit (regression test)" do
      chronicle = FactoryBot.create(:chronicle, team: team, visibility: "internal")
      get "/current_team/content_visibility/#{chronicle.to_param}"
      expect(response).to be_successful
      expect(response.body).to include("Edit content visibility")
    end
  end

  describe "GET /edit" do
    it "renders the edit visibility form for a chronicle" do
      chronicle = FactoryBot.create(:chronicle, team: team, visibility: "internal")
      get current_team_edit_content_visibility_url(chronicle)
      expect(response).to be_successful
      expect(response.body).to include("Edit content visibility")
    end

    it "renders the edit visibility form for a picture" do
      picture = FactoryBot.create(:picture, team: team, visibility: "internal")
      get current_team_edit_content_visibility_url(picture)
      expect(response).to be_successful
      expect(response.body).to include("Edit content visibility")
    end
  end

  describe "PATCH /update" do
    it "publishes a chronicle and cascades published visibility to all attached entries" do
      chronicle = FactoryBot.create(:chronicle, team: team, visibility: "internal")
      picture = FactoryBot.create(:picture, team: team, visibility: "internal")
      thought = FactoryBot.create(:thought, team: team, visibility: "internal")
      FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: picture)
      FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: thought)

      patch current_team_content_visibility_url(chronicle), params: { visibility: "published" }

      expect(response).to redirect_to(current_team_edit_content_visibility_url(chronicle))
      expect(chronicle.reload.visibility).to eq("published")
      expect(picture.reload.visibility).to eq("published")
      expect(thought.reload.visibility).to eq("published")
    end

    it "publishes a memory and cascades published visibility to all attached insights" do
      picture = FactoryBot.create(:picture, team: team, visibility: "internal")
      thought = FactoryBot.create(:thought, team: team, visibility: "internal")
      memory = FactoryBot.create(:memory, team: team, picture: picture, thought: thought, visibility: "internal")

      patch current_team_content_visibility_url(memory), params: { visibility: "published" }

      expect(response).to redirect_to(current_team_edit_content_visibility_url(memory))
      expect(memory.reload.visibility).to eq("published")
      expect(picture.reload.visibility).to eq("published")
      expect(thought.reload.visibility).to eq("published")
    end

    it "prohibits reducing visibility of an insight attached to a published chronicle" do
      chronicle = FactoryBot.create(:chronicle, team: team, name: "Published Journey", visibility: "published")
      picture = FactoryBot.create(:picture, team: team, visibility: "published")
      FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: picture)

      patch current_team_content_visibility_url(picture), params: { visibility: "internal" }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("cannot be limited to &#39;internal&#39;")
      expect(response.body).to include("Published Journey")
      expect(picture.reload.visibility).to eq("published")
    end

    it "gracefully skips lowering an insight's visibility when reducing chronicle if shared with a published memory" do
      chronicle = FactoryBot.create(:chronicle, team: team, visibility: "published")
      picture = FactoryBot.create(:picture, team: team, visibility: "published")
      thought = FactoryBot.create(:thought, team: team, visibility: "published")
      FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: picture)
      FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: thought)

      # Memory is also published with this picture
      FactoryBot.create(:memory, team: team, picture: picture, visibility: "published")

      patch current_team_content_visibility_url(chronicle), params: { visibility: "internal" }

      expect(response).to redirect_to(current_team_edit_content_visibility_url(chronicle))
      expect(chronicle.reload.visibility).to eq("internal")
      expect(thought.reload.visibility).to eq("internal")
      expect(picture.reload.visibility).to eq("published")
    end
  end
end
