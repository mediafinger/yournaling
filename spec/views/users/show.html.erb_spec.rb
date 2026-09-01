# frozen_string_literal: true

RSpec.describe "users/show", type: :view do
  let(:user) { FactoryBot.create(:user) }

  before do
    assign(:user, user)
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to include("Name")
    expect(rendered).to include("Email")
  end
end
