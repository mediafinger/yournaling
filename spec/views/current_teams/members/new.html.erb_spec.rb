RSpec.describe "current_teams/members/new", type: :view do
  before do
    assign(:member, Member.new(
      user: nil,
      team: nil,
      roles: "MyText"
    ))
  end

  it "renders new member form" do
    render
    assert_select "form[action=?][method=?]", current_team_members_path, "post" do
      assert_select "input[name=?]", "member[user_yid]"
      assert_select "input[name=?]", "member[team_yid]"
      assert_select "textarea[name=?]", "member[roles]"
    end
  end
end
