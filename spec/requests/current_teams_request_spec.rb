RSpec.describe "/current_teams", type: :system do
  let(:member) { FactoryBot.create(:member) }
  let(:user) { member.user }
  let(:team) { member.team }

  before { sign_in(user) }

  describe "GET /index" do
    it "renders a successful response", aggregate_failures: true do
      visit current_teams_url

      expect(page).to have_current_path("/current_teams", ignore_query: true)
      expect(page.status_code).to eq(200) # not supported by selenium driver

      main = page.find("main")
      expect(main).to have_text(team.name)
    end
  end

  describe "GET /show" do
    it "renders a successful response" do
      allow(Current).to receive(:team).and_return(team)

      visit current_team_url(team.urlsafe_id)

      expect(page).to have_current_path("/current_teams/#{team.urlsafe_id}", ignore_query: true)
      expect(page.status_code).to eq(200) # not supported by selenium driver
    end
  end

  describe "POST /create", aggregate_failures: true do
    context "with valid parameters" do
      it "selects the Team and redirects to its show page" do
        login(user)

        expect(Current.team).to be_nil

        post current_teams_path, params: { current_team: { team_yid: team.yid } }

        expect(session[:team_yid]).to eq(team.yid)

        expect(response).to redirect_to(team_path(team))
      end
    end
  end
end
