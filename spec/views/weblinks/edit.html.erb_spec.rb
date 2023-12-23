require "rails_helper"

RSpec.describe "weblinks/edit", type: :view do
  let(:weblink) {
    Weblink.create!(
      url: "MyText",
      name: "MyString",
      description: "MyText",
      preview_snippet: ""
    )
  }

  before do
    assign(:weblink, weblink)
  end

  it "renders the edit weblink form" do
    render

    assert_select "form[action=?][method=?]", weblink_path(weblink), "post" do
      assert_select "textarea[name=?]", "weblink[url]"

      assert_select "input[name=?]", "weblink[name]"

      assert_select "textarea[name=?]", "weblink[description]"

      assert_select "input[name=?]", "weblink[preview_snippet]"
    end
  end
end
