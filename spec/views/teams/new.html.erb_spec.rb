RSpec.describe "teams/new", type: :view do
  before do
    assign(:team, Team.new(
      name: "MyString"
    ))
  end

  it "renders new team form" do
    render

    assert_select "form[action=?][method=?]", teams_path, "post" do
      assert_select "input[name=?]", "team[name]"
    end
  end
end
