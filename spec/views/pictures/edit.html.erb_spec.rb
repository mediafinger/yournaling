RSpec.describe "pictures/edit", type: :view do
  let(:picture) { FactoryBot.create(:picture, team: team) }
  let(:user) { FactoryBot.create(:user) }
  let(:team) { FactoryBot.create(:team) }

  before do
    assign(:picture, picture)
  end

  it "renders the edit picture form" do
    Current.user = user
    Current.team = team

    render

    assert_select "form[enctype=?][action=?][method=?]", "multipart/form-data", picture_path(picture.urlsafe_id), "post" do
      assert_select "input[name=?]", "picture[name]"
    end
  end
end
