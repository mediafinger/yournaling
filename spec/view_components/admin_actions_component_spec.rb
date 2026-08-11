# frozen_string_literal: true

require "rails_helper"

RSpec.describe AdminActionsComponent, type: :component do
  let(:team) { FactoryBot.create(:team) }
  let(:location) { FactoryBot.create(:location, team: team) }

  context "when action_name is index" do
    before do
      allow_any_instance_of(described_class).to receive(:action_name).and_return("index") # rubocop:disable RSpec/AnyInstance
    end

    it "renders show, edit, and history action buttons" do
      rendered = render_inline(described_class.new(record: location, name: "location"))

      expect(rendered.to_html).to have_link("Show this location", href: "/admin/locations/#{location.to_param}")
      expect(rendered.to_html).to have_link("Edit this location", href: "/admin/locations/#{location.to_param}/edit")
      expect(rendered.to_html).to have_link("Events", href: "/admin/record_events?record_id=#{location.to_param}")
    end
  end

  context "when action_name is show" do
    before do
      allow_any_instance_of(described_class).to receive(:action_name).and_return("show") # rubocop:disable RSpec/AnyInstance
    end

    it "hides show button and renders edit and history buttons" do
      rendered = render_inline(described_class.new(record: location, name: "location"))

      expect(rendered.to_html).to have_no_link("Show this location")
      expect(rendered.to_html).to have_link("Edit this location", href: "/admin/locations/#{location.to_param}/edit")
      expect(rendered.to_html).to have_link("Events", href: "/admin/record_events?record_id=#{location.to_param}")
    end
  end
end
