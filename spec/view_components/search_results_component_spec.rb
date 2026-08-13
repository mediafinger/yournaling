# frozen_string_literal: true

require "rails_helper"

RSpec.describe SearchResultsComponent, type: :component do
  let(:team) { FactoryBot.create(:team) }
  let(:location) { FactoryBot.create(:location, team: team, name: "Sierra Nevada Camp") }
  let(:user) { FactoryBot.create(:user, name: "Jane Doe") }
  let(:member) { Member.create!(team: team, user: user, roles: %w[editor]) }

  context "when scope is current_team" do
    it "renders links to current_team resource paths" do
      results = [
        {
          "searchable_id" => location.id,
          "updated_at" => "2026-08-10T12:00:00Z",
        },
        {
          "searchable_id" => member.id,
          "updated_at" => "2026-08-10T12:00:00Z",
        },
      ]

      rendered = render_inline(described_class.new(results: results, scope: "current_team"))

      expect(rendered.to_html).to have_link(
        "Location: Sierra Nevada Camp",
        href: "/current_team/locations/#{location.to_param}"
      )
      expect(rendered.to_html).to have_link(
        "Member: #{member.name}",
        href: "/current_team/members/#{member.to_param}"
      )
      expect(rendered.to_html).to include("2026-08-10 12:00:00")
    end
  end

  context "when scope is general" do
    it "renders links to team browse resource paths" do
      results = [
        {
          "searchable_id" => team.id,
          "updated_at" => "2026-08-10T12:00:00Z",
        },
        {
          "searchable_id" => location.id,
          "updated_at" => "2026-08-10T12:00:00Z",
        },
        {
          "searchable_id" => member.id,
          "updated_at" => "2026-08-10T12:00:00Z",
        },
      ]

      rendered = render_inline(described_class.new(results: results, scope: "general"))

      expect(rendered.to_html).to have_link(
        "Team: #{team.name}",
        href: "/teams/#{team.to_param}"
      )
      expect(rendered.to_html).to have_link(
        "Location: Sierra Nevada Camp",
        href: "/teams/#{team.to_param}/locations/#{location.to_param}"
      )
      expect(rendered.to_html).to have_link(
        "Member: #{member.name}",
        href: "/teams/#{team.to_param}/members/#{member.to_param}"
      )
      expect(rendered.to_html).to include("2026-08-10 12:00:00")
    end
  end

  context "when results is a Hash (e.g. from ActionController::Parameters)" do
    it "renders links properly from hash values" do
      results = {
        "0" => {
          "searchable_id" => location.id,
          "updated_at" => "2026-08-10T12:00:00Z",
        },
      }

      rendered = render_inline(described_class.new(results: results, scope: "current_team"))

      expect(rendered.to_html).to have_link(
        "Location: Sierra Nevada Camp",
        href: "/current_team/locations/#{location.to_param}"
      )
    end
  end

  it "renders an empty notice when query is provided but results are empty" do
    rendered = render_inline(described_class.new(results: [], query: "missing"))
    expect(rendered.to_html).to include("No results found.")
  end

  it "renders nothing when results are empty and no query was provided" do
    rendered = render_inline(described_class.new(results: []))
    expect(rendered.to_html).to be_blank
  end
end
