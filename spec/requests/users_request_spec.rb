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

RSpec.describe "/users", type: :request do
  let(:name) { Faker::Name.unique.name }
  let(:email) { "#{name.parameterize.underscore}@example.com" }
  let(:password) { "foobar1234" }

  let(:valid_attributes) { { name: name, email: email, password: password } }
  let(:invalid_attributes) { { name: name, email: nil } }

  describe "GET /index" do
    it "renders a successful response" do
      user = User.create! valid_attributes

      sign_in(user)

      get users_url

      expect(response).to be_successful
    end

    it "is forbidden for guests" do
      get users_url

      expect(response).to be_forbidden
    end
  end

  describe "GET /show" do
    it "renders a successful response" do
      user = User.create! valid_attributes
      get user_url(user)
      expect(response).to be_successful
    end
  end

  describe "GET /new" do
    it "renders a successful response" do
      get new_user_url
      expect(response).to be_successful
    end
  end

  describe "GET /edit" do
    let(:user) { User.create! valid_attributes }

    it "renders a successful response" do
      sign_in(user)

      get edit_user_url(user)

      expect(response).to be_successful
    end

    it "is forbidden for guests" do
      get edit_user_url(user)

      expect(response).to be_forbidden
    end

    it "is forbidden for to edit other users" do
      other_user = FactoryBot.create(:user)

      sign_in(user)

      get edit_user_url(other_user)

      expect(response).to be_forbidden
    end
  end

  describe "POST /create" do
    context "with valid parameters" do
      it "creates a new User" do
        expect {
          post users_url, params: { user: valid_attributes }
        }.to change { User.count }.by(1)
      end

      it "redirects to the created user" do
        post users_url, params: { user: valid_attributes }
        expect(response).to redirect_to(user_url(User.last))
      end
    end

    context "with invalid parameters" do
      it "does not create a new User" do
        expect {
          post users_url, params: { user: invalid_attributes }
        }.to change { User.count }.by(0)
      end

      it "renders a response with 422 status (i.e. to display the 'new' template)" do
        post users_url, params: { user: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "PATCH /update" do
    let(:user) { User.create! valid_attributes }

    context "with valid parameters" do
      let(:new_attributes) { { name: "New Name" } }

      before { sign_in(user) }

      it "updates the requested user" do
        patch user_url(user), params: { user: new_attributes }

        user.reload
        expect(user.name).to eq("New Name")
      end

      it "redirects to the user" do
        patch user_url(user), params: { user: new_attributes }

        user.reload
        expect(response).to redirect_to(user_url(user))
      end
    end

    context "with invalid parameters" do
      it "renders a response with 422 status (i.e. to display the 'edit' template)" do
        sign_in(user)

        patch user_url(user), params: { user: invalid_attributes }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when trying to update another user" do
      let(:new_attributes) { { name: "New Name" } }

      it "is forbidden for guests" do
        patch user_url(user), params: { user: new_attributes }

        expect(response).to be_forbidden
      end

      it "is forbidden for to edit other users" do
        other_user = FactoryBot.create(:user)

        sign_in(user)

        patch user_url(other_user), params: { user: new_attributes }

        expect(response).to be_forbidden
      end
    end
  end

  describe "DELETE /destroy" do
    let(:user) { User.create! valid_attributes }

    before { sign_in(user) }

    it "destroys the requested user and redirects to the users list" do
      expect {
        delete user_url(user)
      }.to change { User.count }.by(-1)

      expect(response).to redirect_to(users_url)
    end

    context "when trying to delete another user" do
      it "is forbidden for guests" do
        sign_out

        delete user_url(user)

        expect(response).to be_forbidden
      end

      it "is forbidden for to edit other users" do
        other_user = FactoryBot.create(:user)

        sign_in(user)

        delete user_url(other_user)

        expect(response).to be_forbidden
      end
    end
  end
end
