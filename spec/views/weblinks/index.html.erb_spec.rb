require "rails_helper"

RSpec.describe "weblinks/index", type: :view do
  before do
    assign(:weblinks, [
             Weblink.create!(
               url: "MyText",
               name: "Name",
               description: "MyText",
               preview_snippet: ""
             ),
             Weblink.create!(
               url: "MyText",
               name: "Name",
               description: "MyText",
               preview_snippet: ""
             ),
           ])
  end

  it "renders a list of weblinks" do
    render
    cell_selector = Rails::VERSION::STRING >= "7" ? "div>p" : "tr>td"
    assert_select cell_selector, text: Regexp.new("MyText".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Name".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("MyText".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("".to_s), count: 2
  end
end
