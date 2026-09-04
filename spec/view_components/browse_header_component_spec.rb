# frozen_string_literal: true

require "rails_helper"

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
  let(:memory) { FactoryBot.create(:memory, team: team, memo: "A memorable moment on the hill", visibility: "published") }

  it "renders the record name as an h4 and a link to the show page — no date, no team in the header" do
    rendered = render_inline(described_class.new(record: chronicle, team: team))

    expect(rendered.to_html).to have_css("h4.yui-record-header__title", text: "Alpine Trek")
    expect(rendered.to_html).to have_link("Open", href: "/teams/#{team.to_param}/chronicles/#{chronicle.to_param}")
    expect(rendered.to_html).not_to include("2026-07-01")
    expect(rendered.to_html).not_to include("Voyagers")
  end

  it "renders no title for a memory — its memo already shows in full in the card body — but keeps the Open link" do
    rendered = render_inline(described_class.new(record: memory, team: team))

    expect(rendered.to_html).to have_no_css("h4.yui-record-header__title")
    expect(rendered.to_html).to have_link("Open", href: "/teams/#{team.to_param}/memories/#{memory.to_param}")
  end

  it "renders in a guest context without raising on current_member (Lookbook / public browse)" do
    expect { render_inline(described_class.new(record: chronicle, team: team)) }.not_to raise_error
  end

  it "does not render the Open link when full is true" do
    rendered = render_inline(described_class.new(record: chronicle, team: team, full: true))

    expect(rendered.to_html).to have_no_link("Open")
  end

  context "when user has edit permission for the team" do
    let(:user) { FactoryBot.create(:user) }
    let!(:member) { Member.create!(team: team, user: user, roles: %w[owner publisher]) }

    it "renders the Rewrite link for an authorized team member" do
      rendered = render_inline(described_class.new(record: chronicle, team: team, user: user, member: member))

      expect(rendered.to_html).to have_link("Rewrite", href: "/current_team/chronicles/#{chronicle.to_param}/edit")
    end
  end
end
