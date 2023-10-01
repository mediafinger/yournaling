RSpec.describe "members/show", type: :view do
  let(:member) { FactoryBot.create(:member) }

  before do
    assign(:member, member)
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/#{member.user_yid}/)
    expect(rendered).to match(/#{member.team_yid}/)
    expect(rendered).to match(/#{member.roles}/)
  end
end
