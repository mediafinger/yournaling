# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/current_team/stories", type: :request do
  let!(:member) { Member.create!(team: team, user: user, roles: Array(roles.sample)) }

  let(:team) { FactoryBot.create(:team) }
  let(:user) { FactoryBot.create(:user) }
  let(:roles) { %i[owner manager editor] }

  let(:valid_attributes) do
    { name: "Day 3: Granada", content: "We climbed to the Mirador de San Nicolás at dusk.", date: Date.current, team: team }
  end
  let(:invalid_attributes) { { name: "", content: "", date: nil } }

  before do
    sign_in(user)
    switch_current_team(team)
  end

  describe "GET /index" do
    it "renders a successful response" do
      Story.create!(valid_attributes)
      get current_team_stories_url
      expect(response).to be_successful
    end

    it "lays the cards out in the shared responsive record grid" do
      Story.create!(valid_attributes)
      get current_team_stories_url
      expect(response.body).to include("yui-record-grid")
    end
  end

  describe "GET /show" do
    it "renders the rendered Markdown" do
      story = Story.create!(valid_attributes.merge(content: "## Sunset\n\nGolden light over the Alhambra."))
      get current_team_story_url(story)
      expect(response).to be_successful
      expect(response.body).to include("<h2")
      expect(response.body).to include("Golden light over the Alhambra.")
    end
  end

  describe "GET /new and /edit" do
    it "renders the Marksmith editor" do
      get new_current_team_story_url
      expect(response).to be_successful
      expect(response.body).to include('data-controller="marksmith list-continuation"')
    end

    it "renders edit" do
      story = Story.create!(valid_attributes)
      get edit_current_team_story_url(story)
      expect(response).to be_successful
    end
  end

  describe "POST /create" do
    context "with valid parameters" do
      it "creates a Story and emits a RecordEvent, storing raw Markdown" do
        expect {
          post current_team_stories_url,
            params: { story: { name: "A Title", content: "# Heading\n\nSome **markdown** body text." } }
        }.to change { Story.count }.by(1).and change { RecordEvent.count }.by(1)

        expect(Story.first.content).to eq("# Heading\n\nSome **markdown** body text.")
        expect(RecordEvent.last.record_type).to eq("story")
      end

      it "redirects to the created story" do
        post current_team_stories_url,
          params: { story: { name: "A Title", content: "A body long enough to pass validation." } }
        expect(response).to redirect_to(current_team_story_url(Story.first))
      end
    end

    context "with invalid parameters" do
      it "does not create a Story and responds 422" do
        expect {
          post current_team_stories_url, params: { story: invalid_attributes }
        }.not_to(change { Story.count })
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "with JSON format" do
      it "returns the new story as JSON" do
        post current_team_stories_url(format: :json),
          params: { story: { name: "JSON Story", content: "Body text that is definitely long enough." } }
        expect(response).to have_http_status(:created)
        json = response.parsed_body
        expect(json["type"]).to eq("story")
        expect(json["text"]).to eq("JSON Story")
      end
    end

    context "when member has unauthorized role (publisher)" do
      before { member.update!(roles: %w[publisher]) }

      it "forbids creating a story" do
        post current_team_stories_url, params: { story: { name: "x", content: "Body text that is long enough here." } }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "PATCH /update" do
    let!(:story) { Story.create!(valid_attributes) }

    it "updates the story" do
      patch current_team_story_url(story), params: { story: { content: "A rewritten body, still long enough." } }
      expect(story.reload.content).to eq("A rewritten body, still long enough.")
      expect(response).to redirect_to(current_team_story_url(story))
    end
  end

  describe "DELETE /destroy" do
    let!(:story) { Story.create!(valid_attributes) }

    context "when member has authorized role" do
      before { member.update!(roles: %w[owner]) }

      it "destroys an unreferenced story" do
        expect { delete current_team_story_url(story) }.to change { Story.count }.by(-1)
        expect(response).to redirect_to(current_team_stories_url)
      end

      it "refuses to destroy a story referenced by a chronicle" do
        chronicle = FactoryBot.create(:chronicle, team: team)
        FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: story)

        expect { delete current_team_story_url(story) }.not_to(change { Story.count })
        expect(response).to redirect_to(edit_current_team_story_url(story))
      end
    end

    context "when member has unauthorized role (editor)" do
      before { member.update!(roles: %w[editor]) }

      it "forbids deleting" do
        delete current_team_story_url(story)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
