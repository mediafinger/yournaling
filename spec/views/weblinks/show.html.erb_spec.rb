require "rails_helper"

RSpec.describe "weblinks/show", type: :view do
  before do
    assign(:weblink, Weblink.create!(
      url: "MyText",
      name: "Name",
      description: "MyText",
      preview_snippet: ""
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/MyText/)
    expect(rendered).to match(/Name/)
    expect(rendered).to match(/MyText/)
    expect(rendered).to match(//)
  end
end
