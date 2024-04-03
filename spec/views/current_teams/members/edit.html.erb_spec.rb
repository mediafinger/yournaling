RSpec.describe "current_teams/members/edit", type: :view do
  let(:member) { FactoryBot.create(:member) }

  before do
    assign(:member, member)
  end

  it "renders the edit member form" do
    render

    assert_select "form[action=?][method=?]", current_team_member_path(member), "post" do
      assert_select "input[name=?]", "member[user_yid]"
      assert_select "input[name=?]", "member[team_yid]"
      assert_select "textarea[name=?]", "member[roles]"
    end
  end
end
