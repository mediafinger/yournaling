RSpec.describe "members/show", type: :view do
  let(:member) { FactoryBot.create(:member) }

  before do
    assign(:member, member)
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/#{member.user.name}/)
    expect(rendered).to match(/#{member.team.name}/)
    expect(rendered).to match(/#{member.roles}/)
  end
end
