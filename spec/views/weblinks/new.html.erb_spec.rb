require "rails_helper"

RSpec.describe "weblinks/new", type: :view do
  let(:team) { FactoryBot.create(:team) }
  let(:weblink) { FactoryBot.build(:weblink, team: team) }

  before do
    assign(:weblink, weblink)
  end

  it "renders new weblink form" do
    Current.team = team

    render

    assert_select "form[action=?][method=?]", weblinks_path, "post" do
      assert_select "input[name=?]", "weblink[name]"

      assert_select "input[name=?]", "weblink[url]"

      assert_select "textarea[name=?]", "weblink[description]"
    end
  end
end
