require "rails_helper"

RSpec.describe "current_teams/locations/edit", type: :view do
  let(:user) { FactoryBot.create(:user) }
  let(:team) { FactoryBot.create(:team) }

  let(:location) {
    Location.create!(
      name: "MyString",
      country_code: "de",
      address: "",
      lat: "9.99",
      long: "9.99",
      url: "MyText",
      team: team
    )
  }

  before do
    allow(view).to receive(:current_team).and_return(team)
    assign(:location, location)
  end

  it "renders the edit location form" do
    render

    assert_select "form[action=?][method=?]", current_team_location_path(location), "post" do
      assert_select "input[name=?]", "location[name]"
      assert_select "select[name=?]", "location[country_code]"
      assert_select "input[name=?]", "location[address]"
      assert_select "input[name=?]", "location[lat]"
      assert_select "input[name=?]", "location[long]"
      assert_select "input[name=?]", "location[url]"
      assert_select "textarea[name=?]", "location[description]"
    end
  end
end
