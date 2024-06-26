require "rails_helper"

RSpec.describe "current_teams/locations/new", type: :view do
  let(:user) { FactoryBot.create(:user) }
  let(:team) { FactoryBot.create(:team) }

  before do
    allow(view).to receive(:current_team).and_return(team)

    assign(:location, Location.new(
      name: "MyString",
      country_code: "de",
      address: "",
      lat: "9.99",
      long: "9.99",
      url: "MyText",
      team: team
    ))
  end

  it "renders new location form" do
    render

    assert_select "form[action=?][method=?]", current_team_locations_path, "post" do
      assert_select "input[name=?]", "location[name]"
      assert_select "select[name=?]", "location[country_code]"
      assert_select "input[name=?]", "location[address]" # TODO
      assert_select "input[name=?]", "location[lat]"
      assert_select "input[name=?]", "location[long]"
      assert_select "input[name=?]", "location[url]"
      assert_select "textarea[name=?]", "location[description]"
    end
  end
end
