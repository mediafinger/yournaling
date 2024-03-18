require "rails_helper"

RSpec.describe "weblinks/show", type: :view do
  let(:team) { FactoryBot.create(:team) }
  let(:weblink) { FactoryBot.create(:weblink, team: team) }

  it "renders attributes in <p>" do
    expect(weblink.valid?).to be true

    assign(:weblink, weblink)

    Current.team = team

    render

    expect(rendered).to match(/#{weblink.name}/)
    expect(rendered).to match(/#{weblink.url}/)
  end
end
