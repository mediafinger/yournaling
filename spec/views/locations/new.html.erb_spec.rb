require "rails_helper"

RSpec.describe "locations/new", type: :view do
  let(:user) { FactoryBot.create(:user) }
  let(:team) { FactoryBot.create(:team) }

  before do
    assign(:location, Location.new(
      name: "MyString",
      url: "MyText",
      lat: "9.99",
      long: "9.99",
      address: "",
      team: team
    ))
  end

  it "renders new location form" do
    Current.user = user
    Current.team = team

    render

    assert_select "form[action=?][method=?]", locations_path, "post" do
      assert_select "input[name=?]", "location[name]"
      assert_select "textarea[name=?]", "location[url]"
      assert_select "input[name=?]", "location[lat]"
      assert_select "input[name=?]", "location[long]"
      assert_select "input[name=?]", "location[address]" # TODO
    end
  end
end
