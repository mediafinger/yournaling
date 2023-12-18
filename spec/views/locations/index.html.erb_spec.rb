require "rails_helper"

RSpec.describe "locations/index", type: :view do
  before do
    assign(:locations, [
             Location.create!(
               name: "Name",
               url: "MyText",
               lat: "9.99",
               long: "9.99",
               address: "",
               team: nil
             ),
             Location.create!(
               name: "Name",
               url: "MyText",
               lat: "9.99",
               long: "9.99",
               address: "",
               team: nil
             ),
           ])
  end

  it "renders a list of locations" do
    render
    cell_selector = Rails::VERSION::STRING >= "7" ? "div>p" : "tr>td"
    assert_select cell_selector, text: Regexp.new("Name".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("MyText".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
  end
end
