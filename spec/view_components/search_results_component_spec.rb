# frozen_string_literal: true

require "rails_helper"

RSpec.describe SearchResultsComponent, type: :component do
  let(:team) { FactoryBot.create(:team) }
  let(:location) { FactoryBot.create(:location, team: team, name: "Sierra Nevada Camp") }
  let(:user) { FactoryBot.create(:user, name: "Jane Doe") }
  let(:member) { Member.create!(team: team, user: user, roles: %w[editor]) }

  context "when scope is current_team" do
    it "renders links to current_team resource paths" do
      doc = PgSearch::Document.find_by(searchable_type: "Location", searchable_id: location.id)
      results = PgSearch::Document.where(id: doc.id)

      rendered = render_inline(described_class.new(results: results, scope: "current_team"))

      expect(rendered.to_html).to have_link(
        href: "/current_team/locations/#{location.to_param}"
      )
      expect(rendered.to_html).to include(doc.content.truncate(60))
    end
  end

  context "when scope is general" do
    it "renders links to team browse resource paths" do
      doc = PgSearch::Document.find_by(searchable_type: "Location", searchable_id: location.id)
      results = PgSearch::Document.where(id: doc.id)

      rendered = render_inline(described_class.new(results: results, scope: "general"))

      expect(rendered.to_html).to have_link(
        href: "/teams/#{team.to_param}/locations/#{location.to_param}"
      )
      expect(rendered.to_html).to include(doc.content.truncate(60))
    end

    it "renders links for Team results" do
      doc = PgSearch::Document.find_by(searchable_type: "Team", searchable_id: team.id)
      results = PgSearch::Document.where(id: doc.id)

      rendered = render_inline(described_class.new(results: results, scope: "general"))

      expect(rendered.to_html).to have_link(
        "Team: #{doc.content.truncate(60)}",
        href: "/teams/#{team.to_param}"
      )
    end
  end

  it "renders Memory results using the content (memo) as display label" do
    memory = FactoryBot.create(:memory, team: team, memo: "My first memory")
    doc = PgSearch::Document.find_by(searchable_type: "Memory", searchable_id: memory.id)
    results = PgSearch::Document.where(id: doc.id)

    rendered = render_inline(described_class.new(results: results, scope: "current_team"))

    expect(rendered.to_html).to have_link("Memory: #{doc.content.truncate(60)}")
    expect(rendered.to_html).to include("My first memory")
  end

  it "renders Thought results using the content (text) as display label" do
    thought = FactoryBot.create(:thought, team: team, text: "An interesting thought")
    doc = PgSearch::Document.find_by(searchable_type: "Thought", searchable_id: thought.id)
    results = PgSearch::Document.where(id: doc.id)

    rendered = render_inline(described_class.new(results: results, scope: "current_team"))

    expect(rendered.to_html).to have_link("Thought: #{doc.content.truncate(60)}")
    expect(rendered.to_html).to include("An interesting thought")
  end

  it "displays a content snippet from the search index" do
    results = PgSearch::Document.where(searchable_type: "Location", searchable_id: location.id)

    rendered = render_inline(described_class.new(results: results, scope: "current_team"))

    doc = results.first
    expect(rendered.to_html).to include(doc.content.truncate(120))
  end

  it "displays the record's updated_at, not the search document's" do
    record_time = 1.hour.ago.change(usec: 0)
    loc = travel_to(record_time) { FactoryBot.create(:location, team: team, name: "Old Place") }

    # PgSearch::Document was created at record_time; touch it to simulate index rebuild at "now"
    PgSearch::Document.where(searchable_type: "Location", searchable_id: loc.id)
      .update_all(updated_at: Time.current)

    results = PgSearch::Document.where(searchable_type: "Location", searchable_id: loc.id)
    rendered = render_inline(described_class.new(results: results, scope: "current_team"))

    expect(rendered.to_html).to include(record_time.to_fs(:db))
    expect(rendered.to_html).not_to include(Time.current.to_fs(:db))
  end

  it "skips stale index entries and logs a warning" do
    doc = PgSearch::Document.where(searchable_type: "Location", searchable_id: location.id).first
    location.delete # delete without callbacks, leaves the PgSearch::Document orphaned
    stale_results = PgSearch::Document.where(id: doc.id)

    expect(Rails.logger).to receive(:warn).with(/Stale search index entry/)

    rendered = render_inline(described_class.new(results: stale_results, scope: "current_team"))

    expect(rendered.to_html).to have_no_link(href: "/current_team/locations/#{location.to_param}")
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
