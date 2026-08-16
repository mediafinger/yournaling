# frozen_string_literal: true

require "rails_helper"

RSpec.describe PictureSelectFieldComponent, type: :component do
  let(:team) { FactoryBot.create(:team) }
  let(:memory) { FactoryBot.create(:memory, team: team) }
  let!(:picture) { FactoryBot.create(:picture, team: team, name: "Sunset View") }

  it "renders picture selection dropdown with existing pictures and upload field" do
    view_context = ActionController::Base.new.view_context
    form = ActionView::Helpers::FormBuilder.new(:memory, memory, view_context, {})

    rendered = render_inline(described_class.new(form: form, team: team))

    expect(rendered.to_html).to include("Select Existing Picture")
    expect(rendered.to_html).to include("Or Upload New Picture")
    expect(rendered.to_html).to include("Sunset View")
    expect(rendered.to_html).to include("picture_file")
    expect(rendered.to_html).to include('data-picture-select-target="filePreview"')
  end

  it "renders the selected picture thumbnail and name if one is pre-selected" do
    memory.picture = picture
    view_context = ActionController::Base.new.view_context
    form = ActionView::Helpers::FormBuilder.new(:memory, memory, view_context, {})

    rendered = render_inline(described_class.new(form: form, team: team, selected_picture: picture))

    expect(rendered.to_html).to include("Sunset View")
  end
end
