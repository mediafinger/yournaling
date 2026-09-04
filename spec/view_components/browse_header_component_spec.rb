# frozen_string_literal: true

require "rails_helper"

# Used only by ChronicleCardComponent's browse header now — Memory has no
# header at all, and the insight partials don't use this component. Just the
# record name, rendered as a plain-looking link to its show page — actions
# (Rewrite, visibility) live in the card footer, see RecordFooterComponent.
RSpec.describe BrowseHeaderComponent, type: :component do
  let(:team) { FactoryBot.create(:team, name: "Voyagers") }
  let(:chronicle) do
    FactoryBot.create(
      :chronicle,
      team: team,
      name: "Alpine Trek",
      start_date: Date.new(2026, 7, 1),
      end_date: Date.new(2026, 7, 15),
      visibility: "published"
    )
  end

  it "renders the record name as an h4, linked to the show page — no date, no team" do
    rendered = render_inline(described_class.new(record: chronicle, team: team))

    expect(rendered.to_html).to have_css("h4.yui-record-header__title a.yui-link--cover", text: "Alpine Trek")
    expect(rendered.to_html).to have_link("Alpine Trek", href: "/teams/#{team.to_param}/chronicles/#{chronicle.to_param}")
    expect(rendered.to_html).not_to include("2026-07-01")
    expect(rendered.to_html).not_to include("Voyagers")
  end

  it "does not link the title when full is true" do
    rendered = render_inline(described_class.new(record: chronicle, team: team, full: true))

    expect(rendered.to_html).to have_css("h4.yui-record-header__title", text: "Alpine Trek")
    expect(rendered.to_html).to have_no_link("Alpine Trek")
  end

  it "does not link the title when already on the record's own show page" do
    allow_any_instance_of(described_class).to receive_messages(controller_name: "chronicles", action_name: "show") # rubocop:disable RSpec/AnyInstance

    rendered = render_inline(described_class.new(record: chronicle, team: team))

    expect(rendered.to_html).to have_no_link("Alpine Trek")
  end

  it "renders in-memory records (e.g. /example) without raising — no route, so no link" do
    unsaved_team = Team.new(name: "Unsaved")
    unsaved_chronicle = Chronicle.new(name: "Draft", team: unsaved_team, start_date: Date.current)

    rendered = nil
    expect {
      rendered = render_inline(described_class.new(record: unsaved_chronicle, team: unsaved_team))
    }.not_to raise_error

    expect(rendered.to_html).to have_css("h4.yui-record-header__title", text: "Draft")
    expect(rendered.to_html).to have_no_css("a")
  end
end
