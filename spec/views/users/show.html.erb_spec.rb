RSpec.describe "users/show", type: :view do
  let(:user) { FactoryBot.create(:user) }

  before do
    assign(:user, user)
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Name/)
    expect(rendered).to match(/Email/)
  end
end
