require "rails_helper"

RSpec.describe "teams/weblinks/show", type: :view do
  let(:team) { FactoryBot.create(:team) }
  let(:weblink) { FactoryBot.create(:weblink, team: team) }

  before do
    assign(:weblink, weblink)
  end

  it "renders attributes in <p>" do
    render

    # expect(rendered).to include("Name: #{weblink.name}")
    expect(rendered).to have_link(weblink.url, href: weblink.url)
  end
end
