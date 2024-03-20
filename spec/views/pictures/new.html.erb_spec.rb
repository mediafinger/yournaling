RSpec.describe "pictures/new", type: :view do
  let(:user) { FactoryBot.create(:user) }
  let(:team) { FactoryBot.create(:team) }

  before do
    allow(view).to receive(:current_team).and_return(team)
    assign(:picture, Picture.new(
      name: "MyString",
      team: team
    ))
  end

  it "renders new picture form" do
    render

    assert_select "form[action=?][method=?]", pictures_path, "post" do
      assert_select "input[name=?]", "picture[name]"
    end
  end
end
