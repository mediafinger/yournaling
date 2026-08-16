# frozen_string_literal: true

require "rails_helper"

RSpec.describe MemoryAttachInsightsFormComponent, type: :component do
  let(:team) { FactoryBot.create(:team) }
  let(:memory) { FactoryBot.create(:memory, team: team) }
  let!(:picture) { FactoryBot.create(:picture, team: team, name: "Sunset View") }
  let!(:location) { FactoryBot.create(:location, team: team, name: "Cabo de Gata") }
  let!(:thought) { FactoryBot.create(:thought, team: team, text: "A deep thought") }
  let!(:weblink) { FactoryBot.create(:weblink, team: team, name: "Travel Blog") }

  it "renders picture and location selection fields" do
    view_context = ActionController::Base.new.view_context
    form = ActionView::Helpers::FormBuilder.new(:memory, memory, view_context, {})

    rendered = render_inline(described_class.new(form: form, memory: memory))

    expect(rendered.to_html).to include("Select Existing Picture")
    expect(rendered.to_html).to include("Sunset View")
    expect(rendered.to_html).to include("Select Existing Location")
    expect(rendered.to_html).to include("Cabo de Gata")
    expect(rendered.to_html).to include("Or Create New Location")
  end

  it "renders thought and weblink selection fields" do
    view_context = ActionController::Base.new.view_context
    form = ActionView::Helpers::FormBuilder.new(:memory, memory, view_context, {})

    rendered = render_inline(described_class.new(form: form, memory: memory))

    expect(rendered.to_html).to include("Select Existing Thought")
    expect(rendered.to_html).to include("A deep thought")
    expect(rendered.to_html).to include("Select Existing Weblink")
    expect(rendered.to_html).to include("Travel Blog")
    expect(rendered.to_html).to include("Or Create New Thought")
    expect(rendered.to_html).to include("Or Create New Weblink")
  end
end
