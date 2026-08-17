# frozen_string_literal: true

require "rails_helper"

RSpec.describe ChronicleAttachedEntriesFormComponent, type: :component do
  let(:team) { FactoryBot.create(:team) }
  let(:chronicle) { FactoryBot.create(:chronicle, team: team) }
  let!(:picture) { FactoryBot.create(:picture, team: team, name: "Sunset View") }
  let!(:location) { FactoryBot.create(:location, team: team, name: "Cabo de Gata") }
  let!(:thought) { FactoryBot.create(:thought, team: team, text: "A deep thought") }

  let!(:entry1) { FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: picture, position: 1) }
  let!(:entry2) { FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: location, position: 2) }
  let!(:entry3) { FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: thought, position: 3) }

  it "renders sortable container with drag handles and hidden position fields" do
    view_context = ActionController::Base.new.view_context
    form = ActionView::Helpers::FormBuilder.new(:chronicle, chronicle, view_context, {})

    rendered = render_inline(described_class.new(form: form, scope: "current_team"))

    expect(rendered.to_html).to include('data-controller="sortable"')
    expect(rendered.to_html).to include('data-sortable-target="item"')
    expect(rendered.to_html).to include('data-sortable-target="handle"')
    expect(rendered.to_html).to include('data-sortable-target="position"')
    expect(rendered.to_html).to include('data-action="click->sortable#moveUp"')
    expect(rendered.to_html).to include('data-action="click->sortable#moveDown"')
  end

  it "renders attached entry content titles and texts" do
    view_context = ActionController::Base.new.view_context
    form = ActionView::Helpers::FormBuilder.new(:chronicle, chronicle, view_context, {})

    rendered = render_inline(described_class.new(form: form, scope: "current_team"))

    expect(rendered.to_html).to include("Sunset View")
    expect(rendered.to_html).to include("Cabo de Gata")
    expect(rendered.to_html).to include("A deep thought")
  end
end
