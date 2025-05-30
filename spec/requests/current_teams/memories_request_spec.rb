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

RSpec.describe "/current_team/memories", type: :request do
  let(:user) { FactoryBot.create(:user) }
  let(:team) { FactoryBot.create(:team) }
  let(:weblink) { FactoryBot.create(:weblink, team:) }
  let(:roles) { %i[owner manager editor] }

  let(:valid_attributes) { { team_id: team.id, memo: "Memo Text", weblink: } }
  let(:invalid_attributes) { { team_id: team.id, memo: "." } }

  before do
    Member.create!(team: team, user: user, roles: Array(roles.sample))
    sign_in(user)
    switch_current_team(team)
  end

  describe "GET /index" do
    let!(:memory) { Memory.create! valid_attributes }

    context "when no current_team has been selected" do
      before do
        go_solo(team)
      end

      it "forbids access and redirects to home path" do
        get current_team_memories_url
        expect(response).to redirect_to(root_url)
      end
    end

    context "when the same current_team has been selected already" do
      it "renders a successful response" do
        get current_team_memories_url
        expect(response).to be_successful
      end
    end
  end

  describe "GET /show" do
    let!(:memory) { Memory.create! valid_attributes }

    it "renders a successful response" do
      get current_team_memory_url(memory.urlsafe_id)
      expect(response).to be_successful
    end
  end

  describe "GET /new" do
    it "renders a successful response" do
      get new_current_team_memory_url
      expect(response).to be_successful
    end
  end

  describe "GET /edit" do
    let!(:memory) { Memory.create! valid_attributes }

    it "renders a successful response" do
      get edit_current_team_memory_url(memory.urlsafe_id)
      expect(response).to be_successful
    end
  end

  describe "POST /create" do
    context "with valid parameters" do
      it "creates a new Memory" do
        expect {
          post current_team_memories_url, params: { memory: valid_attributes }
        }.to change { Memory.count }.by(1)
      end

      it "redirects to the created memory" do
        post current_team_memories_url, params: { memory: valid_attributes }

        expect(response).to redirect_to(current_team_memory_url(Memory.first.urlsafe_id))
      end
    end

    context "with invalid parameters" do
      it "does not create a new Memory" do
        expect {
          post current_team_memories_url, params: { memory: invalid_attributes }
        }.to change { Memory.count }.by(0)
      end

      it "renders a response with 422 status (i.e. to display the 'new' template)" do
        post current_team_memories_url, params: { memory: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "PATCH /update" do
    context "with valid parameters" do
      let(:location) { FactoryBot.create(:location, team: team) }
      let(:new_attributes) { { location_id: location.id } }

      it "updates the requested memory" do
        memory = Memory.create! valid_attributes

        patch current_team_memory_url(memory), params: { memory: new_attributes }

        memory.reload
        expect(memory.location_id).to eq(location.id)
      end

      it "redirects to the memory" do
        memory = Memory.create! valid_attributes

        patch current_team_memory_url(memory), params: { memory: new_attributes }

        memory.reload
        expect(response).to redirect_to(current_team_memory_url(memory))
      end
    end

    context "with invalid parameters" do
      it "renders a response with 422 status (i.e. to display the 'edit' template)" do
        memory = Memory.create! valid_attributes
        patch current_team_memory_url(memory), params: { memory: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "DELETE /destroy" do
    let(:roles) { %i[owner manager] }

    let!(:memory) { Memory.create! valid_attributes }

    it "destroys the requested memory" do
      expect {
        delete current_team_memory_url(memory)
      }.to change { Memory.count }.by(-1)
    end

    it "redirects to the memories list" do
      delete current_team_memory_url(memory)

      expect(response).to redirect_to(current_team_memories_url)
    end
  end
end
