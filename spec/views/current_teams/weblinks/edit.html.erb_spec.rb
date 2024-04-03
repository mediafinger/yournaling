require "rails_helper"

RSpec.describe "current_teams/weblinks/edit", type: :view do
  let(:team) { FactoryBot.create(:team) }
  let(:weblink) { FactoryBot.create(:weblink, team: team) }

  before do
    allow(view).to receive(:current_team).and_return(team)
    assign(:weblink, weblink)
  end

  it "renders the edit weblink form" do
    render

    assert_select "form[action=?][method=?]", current_team_weblink_path(weblink), "post" do
      assert_select "input[name=?]", "weblink[name]"

      assert_select "input[name=?]", "weblink[url]"

      assert_select "textarea[name=?]", "weblink[description]"
    end
  end
end
