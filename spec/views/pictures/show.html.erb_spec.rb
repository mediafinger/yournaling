RSpec.describe "pictures/show", type: :view do
  let(:picture) { FactoryBot.create(:picture) }

  # value.blob.byte_size => 66914 - but should be in: 153600..6291456
  # value.blob.content_type => "image/jpeg" - but should be in: ["image/webp"]

  it "renders attributes in <p>" do
    picture.updated_by = picture.created_by # HACK: to ensure valid? does not miss this attribute
    expect(picture.valid?).to be true

    assign(:picture, picture)

    render

    expect(rendered).to match(/#{picture.name}/)
  end
end
