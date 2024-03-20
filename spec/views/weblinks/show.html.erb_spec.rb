require "rails_helper"

RSpec.describe "weblinks/show", type: :view do
  let(:team) { FactoryBot.create(:team) }
  let(:weblink) { FactoryBot.create(:weblink, team: team) }

  before do
    allow(view).to receive(:current_team).and_return(team)
    assign(:weblink, weblink)
  end

  it "renders attributes in <p>" do
    render

    expect(rendered).to match(/#{weblink.name}/)
    expect(rendered).to have_link(weblink.url, href: weblink.url)
  end
end
