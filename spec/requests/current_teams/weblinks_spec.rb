require "rails_helper"

# This spec was generated by rspec-rails when you ran the scaffold generator.
# It demonstrates how one might use RSpec to test the controller code that
# was generated by Rails when you ran the scaffold generator.
#
# It assumes that the implementation code is generated by the rails scaffold
# generator. If you are using any extension libraries to generate different
# controller code, this generated spec may or may not pass.
#
# It only uses APIs available in rails and/or rspec-rails. There are a number
# of tools you can use to make these specs even more expressive, but we're
# sticking to rails and rspec-rails APIs to keep things simple and stable.

RSpec.describe "/current_team/weblinks", type: :request do
  let(:team) { FactoryBot.create(:team) }
  let(:user) { FactoryBot.create(:user) }
  let(:roles) { %i[owner manager editor] }

  let(:valid_attributes) { { name: "Yournaling", url: "www.yournaling.com", description: "Your Journaling", team: } }
  let(:invalid_attributes) { { name: nil } }

  before do
    Member.create!(team: team, user: user, roles: Array(roles.sample))
    sign_in(user)
    switch_current_team(team)
  end

  describe "GET /index" do
    it "renders a successful response" do
      Weblink.create! valid_attributes
      get current_team_weblinks_url
      expect(response).to be_successful
    end
  end

  describe "GET /show" do
    it "renders a successful response" do
      weblink = Weblink.create! valid_attributes
      get current_team_weblink_url(weblink)
      expect(response).to be_successful
    end
  end

  describe "GET /new" do
    it "renders a successful response" do
      get new_current_team_weblink_url

      expect(response).to be_successful
    end
  end

  describe "GET /edit" do
    it "renders a successful response" do
      weblink = Weblink.create! valid_attributes

      get edit_current_team_weblink_url(weblink)

      expect(response).to be_successful
    end
  end

  describe "POST /create" do
    context "with valid parameters" do
      it "creates a new Weblink" do
        expect {
          post current_team_weblinks_url, params: { weblink: valid_attributes }
        }.to change { Weblink.count }.by(1)
      end

      it "redirects to the created weblink" do
        post current_team_weblinks_url, params: { weblink: valid_attributes }
        expect(response).to redirect_to(current_team_weblink_url(Weblink.first))
      end
    end

    context "with invalid parameters" do
      it "does not create a new Weblink" do
        expect {
          post current_team_weblinks_url, params: { weblink: invalid_attributes }
        }.to change { Weblink.count }.by(0)
      end

      it "renders a response with 422 status (i.e. to display the 'new' template)" do
        post current_team_weblinks_url, params: { weblink: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "PATCH /update" do
    context "with valid parameters" do
      let(:new_attributes) {
        skip("Add a hash of attributes valid for your model")
      }

      it "updates the requested weblink" do
        weblink = Weblink.create! valid_attributes
        patch current_team_weblink_url(weblink), params: { weblink: new_attributes }
        weblink.reload
        skip("Add assertions for updated state")
      end

      it "redirects to the weblink" do
        weblink = Weblink.create! valid_attributes
        patch current_team_weblink_url(weblink), params: { weblink: new_attributes }
        weblink.reload
        expect(response).to redirect_to(current_team_weblink_url(weblink))
      end
    end

    context "with invalid parameters" do
      it "renders a response with 422 status (i.e. to display the 'edit' template)" do
        weblink = Weblink.create! valid_attributes
        patch current_team_weblink_url(weblink), params: { weblink: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "DELETE /destroy" do
    let(:roles) { %i[owner manager] }

    it "destroys the requested weblink" do
      weblink = Weblink.create! valid_attributes
      expect {
        delete current_team_weblink_url(weblink)
      }.to change { Weblink.count }.by(-1)
    end

    it "redirects to the weblinks list" do
      weblink = Weblink.create! valid_attributes
      delete current_team_weblink_url(weblink)
      expect(response).to redirect_to(current_team_weblinks_url)
    end
  end
end
