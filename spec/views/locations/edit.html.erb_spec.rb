require "rails_helper"

RSpec.describe "locations/edit", type: :view do
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
    assign(:location, location)
  end

  it "renders the edit location form" do
    Current.user = user
    Current.team = team

    render

    assert_select "form[action=?][method=?]", location_path(location), "post" do
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
