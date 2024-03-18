require "rails_helper"

RSpec.describe "weblinks/edit", type: :view do
  let(:team) { FactoryBot.create(:team) }
  let(:weblink) { FactoryBot.create(:weblink, team: team) }

  before do
    assign(:weblink, weblink)
  end

  it "renders the edit weblink form" do
    Current.team = team

    render

    assert_select "form[action=?][method=?]", weblink_path(weblink), "post" do
      assert_select "input[name=?]", "weblink[name]"

      assert_select "input[name=?]", "weblink[url]"

      assert_select "textarea[name=?]", "weblink[description]"
    end
  end
end
