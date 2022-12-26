require "rails_helper"

RSpec.describe "users/new", type: :view do
  let(:user) { FactoryBot.build(:user) }

  before do
    assign(:user, user)
  end

  it "renders new user form" do
    render

    assert_select "form[action=?][method=?]", users_path, "post" do
      assert_select "input[name=?]", "user[name]"
      assert_select "input[name=?]", "user[email]"
      assert_select "input[name=?]", "user[password]"
    end
  end
end
