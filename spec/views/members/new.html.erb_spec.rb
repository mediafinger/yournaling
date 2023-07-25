require "rails_helper"

RSpec.describe "members/new", type: :view do
  before do
    assign(:member, Member.new(
      user: nil,
      team: nil,
      roles: "MyText"
    ))
  end

  it "renders new member form" do
    render
    assert_select "form[action=?][method=?]", members_path, "post" do
      assert_select "input[name=?]", "member[user_yid]"
      assert_select "input[name=?]", "member[team_yid]"
      assert_select "textarea[name=?]", "member[roles]"
    end
  end
end
