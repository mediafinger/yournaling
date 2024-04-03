RSpec.describe "/switch_current_teams", type: :system do
  let(:member) { FactoryBot.create(:member) }
  let(:user) { member.user }
  let(:team) { member.team }

  before { visit_sign_in(user) }

  describe "GET /index" do
    it "renders a successful response", aggregate_failures: true do
      visit switch_current_teams_url

      expect(page).to have_current_path("/switch_current_teams", ignore_query: true)
      expect(page.status_code).to eq(200) # not supported by selenium driver

      main = page.find("main")
      expect(main).to have_text(team.name)
    end
  end

  describe "GET /show" do
    it "renders a successful response" do
      visit_switch_current_team(team)

      visit switch_current_team_url(team.urlsafe_id)

      expect(page).to have_current_path("/switch_current_teams/#{team.urlsafe_id}", ignore_query: true)
      expect(page.status_code).to eq(200) # not supported by selenium driver
    end
  end

  describe "POST /create", aggregate_failures: true do
    context "with valid parameters" do
      it "selects the Team and redirects to its show page" do
        sign_in(user)

        expect(Current.team).to be_nil

        post switch_current_teams_url, params: { current_team: { team_yid: team.yid } }

        expect(session[:team_yid]).to eq(team.yid)

        expect(response).to redirect_to(team_url(team))
      end
    end
  end

  describe "DELETE /destroy", aggregate_failures: true do
    context "when a team is selected" do
      it "removes the current Team selection and redirects to the root_path" do
        sign_in(user)
        switch_current_team(team)

        expect(session[:team_yid]).to eq(team.yid)

        go_solo(team)

        expect(session[:team_yid]).to be_nil
        expect(response).to redirect_to(root_url)
      end
    end
  end
end
