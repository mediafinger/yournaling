require "rails_helper"

RSpec.describe "pictures/show", type: :view do
  let(:picture) { FactoryBot.create(:picture, :with_image) }

  pending "renders attributes in <p>" do
    expect(picture.valid?).to be true

    assign(:picture, picture)

    render

    expect(rendered).to match(/#{picture.name}/)
  end
end
