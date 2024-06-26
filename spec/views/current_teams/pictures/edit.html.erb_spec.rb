RSpec.describe "current_teams/pictures/edit", type: :view do
  let(:picture) { FactoryBot.create(:picture, team: team) }
  let(:user) { FactoryBot.create(:user) }
  let(:team) { FactoryBot.create(:team) }

  before do
    allow(view).to receive(:current_team).and_return(team)
    assign(:picture, picture)
  end

  it "renders the edit picture form" do
    render

    assert_select "form[enctype=?][action=?][method=?]", "multipart/form-data",
      current_team_picture_path(picture.urlsafe_id), "post" do
        assert_select "input[name=?]", "picture[name]"
      end
  end
end
