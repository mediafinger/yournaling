# frozen_string_literal: true

require "rails_helper"

RSpec.describe SearchResultsComponent, type: :component do
  let(:team) { FactoryBot.create(:team) }
  let(:location) { FactoryBot.create(:location, team: team, name: "Sierra Nevada Camp") }

  it "renders links to search results" do
    results = [
      {
        "searchable_id" => location.id,
        "updated_at" => "2026-08-10T12:00:00Z",
      },
    ]

    rendered = render_inline(described_class.new(results: results))

    expect(rendered.to_html).to have_link(
      "Location: Sierra Nevada Camp",
      href: "/current_team/locations/#{location.to_param}"
    )
    expect(rendered.to_html).to include("2026-08-10 12:00:00")
  end

  it "renders nothing when results are empty" do
    rendered = render_inline(described_class.new(results: []))
    expect(rendered.to_html).to be_blank
  end
end
