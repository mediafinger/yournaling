require "rails_helper"

RSpec.describe "locations/new", type: :view do
  before do
    assign(:location, Location.new(
      address: "MyText",
      country_code: "de",
      lat: "9.99",
      long: "9.99",
      name: "MyString",
      link: "MyText"
    ))
  end

  it "renders new location form" do
    render

    assert_select "form[action=?][method=?]", locations_path, "post" do
      assert_select "input[name=?]", "location[address]"
      assert_select "select[name=?]", "location[country_code]"
      assert_select "input[name=?]", "location[lat]"
      assert_select "input[name=?]", "location[long]"
      assert_select "input[name=?]", "location[name]"
      assert_select "input[name=?]", "location[link]"
    end
  end
end
