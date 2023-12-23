require "rails_helper"

RSpec.describe "weblinks/new", type: :view do
  before do
    assign(:weblink, Weblink.new(
      url: "MyText",
      name: "MyString",
      description: "MyText",
      preview_snippet: ""
    ))
  end

  it "renders new weblink form" do
    render

    assert_select "form[action=?][method=?]", weblinks_path, "post" do
      assert_select "textarea[name=?]", "weblink[url]"

      assert_select "input[name=?]", "weblink[name]"

      assert_select "textarea[name=?]", "weblink[description]"

      assert_select "input[name=?]", "weblink[preview_snippet]"
    end
  end
end
