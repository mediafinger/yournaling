require "rails_helper"

RSpec.describe "locations/new", type: :view do
  before do
    assign(:location, Location.new(
      name: "MyString",
      url: "MyText",
      lat: "9.99",
      long: "9.99",
      address: "",
      team: nil
    ))
  end

  it "renders new location form" do
    render

    assert_select "form[action=?][method=?]", locations_path, "post" do
      assert_select "input[name=?]", "location[name]"

      assert_select "textarea[name=?]", "location[url]"

      assert_select "input[name=?]", "location[lat]"

      assert_select "input[name=?]", "location[long]"

      assert_select "input[name=?]", "location[address]"

      assert_select "input[name=?]", "location[team_id]"
    end
  end
end
