require "rails_helper"

RSpec.describe "weblinks/index", type: :view do
  let(:weblinks) { FactoryBot.create_list(:weblink, 2) }

  before do
    assign(:weblinks, weblinks)
  end

  it "renders a list of weblinks" do
    render

    assert_select "article", text: Regexp.new(weblinks.first.name)
    assert_select "article", text: Regexp.new(weblinks.first.url.to_s)

    assert_select "article", text: Regexp.new(weblinks.last.name)
    assert_select "article", text: Regexp.new(weblinks.last.url.to_s)
  end
end
