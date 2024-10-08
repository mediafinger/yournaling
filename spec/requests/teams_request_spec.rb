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

RSpec.describe "/teams", type: :system do
  let(:user) { FactoryBot.create(:user) }
  let(:name) { Faker::Sports::Football.unique.team }

  let(:valid_attributes) { { name: name } }
  let(:invalid_attributes) { { name: nil } }

  describe "GET /index" do
    let(:team) { Team.create! valid_attributes }

    before { FactoryBot.create(:member, user: user, team: team) }

    context "when user logged in" do
      before { visit_sign_in(user) }

      it "renders a successful response", aggregate_failures: true do
        visit teams_url

        expect(page).to have_current_path("/teams", ignore_query: true)
        expect(page.status_code).to eq(200) # not supported by selenium driver

        header = page.find("header")
        expect(header).to have_no_text("Logout Guest")
        expect(header).to have_text("Logout #{user.name}")

        expect(page).to have_text(team.name)
      end
    end

    context "when guest user" do
      it "is forbidden for guests" do
        visit teams_url

        expect(page.status_code).to eq(403) # not supported by selenium driver
      end
    end
  end

  describe "GET /show" do
    let(:team) { Team.create! valid_attributes }

    context "when user logged in" do
      before { visit_sign_in(user) }

      it "renders a successful response" do
        visit team_url(team.urlsafe_id)

        expect(page.status_code).to eq(200) # not supported by selenium driver
      end
    end

    context "when guest user" do
      it "is allowed for guests" do
        visit team_url(team.urlsafe_id)

        expect(page.status_code).to eq(200) # not supported by selenium driver
      end
    end
  end

  describe "GET /new" do
    context "when user logged in" do
      before { visit_sign_in(user) }

      it "renders a successful response" do
        visit new_team_url

        expect(page.status_code).to eq(200) # not supported by selenium driver
      end
    end

    context "when guest user" do
      it "is forbidden for guests" do
        visit new_team_url

        expect(page.status_code).to eq(403) # not supported by selenium driver
      end
    end
  end

  describe "GET /edit" do
    let(:team) { Team.create! valid_attributes }

    context "when user team member and owner" do
      before do
        FactoryBot.create(:member, user: user, team: team, roles: %w[owner])
        visit_sign_in(user)
        visit_switch_current_team(team)
      end

      it "is successful" do
        visit edit_team_url(team.urlsafe_id)

        expect(page.status_code).to eq(200) # not supported by selenium driver
      end
    end

    context "when user team member and has selected team" do
      before do
        FactoryBot.create(:member, user: user, team: team, roles: %w[editor])
        visit_sign_in(user)
        visit_switch_current_team(team)
      end

      it "is forbidden when not team owner" do
        visit edit_team_url(team.urlsafe_id)

        expect(page.status_code).to eq(403) # not supported by selenium driver
      end
    end

    context "when user team member" do
      before do
        FactoryBot.create(:member, user: user, team: team)
        visit_sign_in(user)
      end

      it "is forbidden when not current_team" do
        visit edit_team_url(team.urlsafe_id)

        expect(page.status_code).to eq(403) # not supported by selenium driver
      end
    end

    context "when user logged in" do
      before { visit_sign_in(user) }

      it "renders a successful response" do
        visit edit_team_url(team.urlsafe_id)

        expect(page.status_code).to eq(403) # not supported by selenium driver
      end
    end

    context "when guest user" do
      it "is forbidden for guests" do
        visit edit_team_url(team.urlsafe_id)

        expect(page.status_code).to eq(403) # not supported by selenium driver
      end
    end
  end

  describe "POST /create", aggregate_failures: true do
    context "with valid parameters" do
      before { sign_in(user) }

      it "creates a new Team" do
        expect {
          post teams_url({ team: { name: "New Name" } }) # TODO: do NOT test POST create with capybara!
        }.to change { Team.count }.by(1)

        expect(response).to redirect_to(team_url(Team.first))
      end

      it "redirects to the created team" do
        post teams_url({ team: { name: "New Name" } })

        expect(response).to redirect_to(team_url(Team.first))
      end
    end

    context "with invalid parameters and renders a response with 422 status" do
      before { sign_in(user) }

      it "does not create a new Team" do
        expect {
          post teams_url({ team: invalid_attributes })
        }.to change { Team.count }.by(0)

        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "PATCH /update" do
    let(:team) { Team.create! valid_attributes }

    before { sign_in(user) }

    context "when user team member and owner of current_team" do
      before do
        FactoryBot.create(:member, user: user, team: team, roles: %w[owner])
        switch_current_team(team)
      end

      context "with valid parameters" do
        let(:new_attributes) { { name: "New Name" } }

        it "updates the requested team and redirects to it" do
          patch team_url(team.urlsafe_id), params: { team: new_attributes }

          team.reload
          expect(team.name).to eq("New Name")
          expect(response).to redirect_to(team_url(team.urlsafe_id))
        end
      end

      context "with invalid parameters" do
        it "renders a response with 422 status (i.e. to display the 'edit' template)" do
          patch team_url(team.urlsafe_id), params: { team: invalid_attributes }

          expect(response).to have_http_status(:unprocessable_content)
        end
      end
    end

    context "when user team member and owner of team (but did not select it as current_team)" do
      before do
        FactoryBot.create(:member, user: user, team: team, roles: %w[owner])
      end

      context "with valid parameters" do
        let(:new_attributes) { { name: "New Name" } }

        it "is forbidden" do
          patch team_url(team.urlsafe_id), params: { team: new_attributes }

          team.reload
          expect(team.name).to eq(valid_attributes[:name])
          expect(response).to have_http_status(:forbidden)
        end
      end
    end

    context "when user team member of current_team" do
      before do
        FactoryBot.create(:member, user: user, team: team, roles: %w[editor])
        switch_current_team(team)
      end

      context "with valid parameters" do
        let(:new_attributes) { { name: "New Name" } }

        it "is forbidden" do
          patch team_url(team.urlsafe_id), params: { team: new_attributes }

          team.reload
          expect(team.name).to eq(valid_attributes[:name])
          expect(response).to have_http_status(:forbidden)
        end
      end
    end

    context "with current_user" do
      context "with valid parameters" do
        let(:new_attributes) { { name: "New Name" } }

        it "is forbidden" do
          patch team_url(team.urlsafe_id), params: { team: new_attributes }

          team.reload
          expect(team.name).to eq(valid_attributes[:name])
          expect(response).to have_http_status(:forbidden)
        end
      end
    end

    context "with guest user" do
      before do
        sign_out
      end

      context "with valid parameters" do
        let(:new_attributes) { { name: "New Name" } }

        it "is forbidden" do
          patch team_url(team.urlsafe_id), params: { team: new_attributes }

          team.reload
          expect(team.name).to eq(valid_attributes[:name])
          expect(response).to have_http_status(:forbidden)
        end
      end
    end
  end

  describe "DELETE /destroy" do
    let(:team) { Team.create! valid_attributes }

    before { sign_in(user) }

    context "when user team member and owner of current_team" do
      before do
        FactoryBot.create(:member, user: user, team: team, roles: %w[owner])
        switch_current_team(team)
      end

      it "destroys the requested team and redirects to the teams index page" do
        expect {
          delete team_url(team.urlsafe_id)
        }.to change { Team.count }.to(0)

        expect(response).to redirect_to(teams_url)
      end
    end
  end
end
