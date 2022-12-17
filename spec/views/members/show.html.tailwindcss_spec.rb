require 'rails_helper'

RSpec.describe "members/show", type: :view do
  let(:member) { FactoryBot.create(:member) }

  before do
    assign(:member, member)
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/#{member.user_id}/)
    expect(rendered).to match(/#{member.team_id}/)
    expect(rendered).to match(/#{member.roles}/)
  end
end
