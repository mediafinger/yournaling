# frozen_string_literal: true

require "rails_helper"

RSpec.describe MemoryCardComponent, type: :component do
  let(:team) { FactoryBot.build_stubbed(:team, name: "The Coast Year") }
  let(:memory) {
    FactoryBot.build_stubbed(:memory, weblink: nil, memo: "We found a whole sand dollar, unbroken.", team: team)
  }

  it "has no header at all — the memo is always shown in full, so there's nothing to open" do
    rendered = render_inline(described_class.new(memory: memory, scope: :browse, team: team))

    expect(rendered).to have_css("article.yui-card.yui-memory-card[id='#{ActionView::RecordIdentifier.dom_id(memory)}']")
    expect(rendered).to have_no_css(".yui-record-header")
    expect(rendered).to have_no_css("h4")
    expect(rendered).to have_no_css(".yui-badge", text: "Memory")
    expect(rendered).to have_no_css(".yui-btn", text: "Open")
    expect(rendered).to have_css(".yui-memory-card__memo", text: "sand dollar")
  end

  it "renders a footer with the date and an @team link" do
    rendered = render_inline(described_class.new(memory: memory, scope: :browse, team: team))

    expect(rendered).to have_css(".yui-card-footer")
    expect(rendered).to have_link("@The Coast Year", href: "/teams/#{team.to_param}")
  end

  it "renders an attached thought as a blockquote" do
    memory.thought = Thought.new(text: "Some days keep themselves.")

    rendered = render_inline(described_class.new(memory: memory, scope: :browse, team: team))

    expect(rendered).to have_css(".yui-blockquote blockquote", text: "Some days keep themselves.")
  end

  it "renders an attached location as a chip" do
    memory.location = FactoryBot.build_stubbed(:location, name: "Ericeira", country_code: "pt")

    rendered = render_inline(described_class.new(memory: memory, scope: :browse, team: team))

    expect(rendered).to have_css("span.yui-tag", text: "Ericeira")
  end

  it "wires the footer with show_rewrite / show_visibility off when hide_actions is true" do
    rendered = render_inline(described_class.new(memory: memory, scope: :manage, team: team, hide_actions: true))

    expect(rendered).to have_no_css(".yui-btn", text: "Rewrite")
    expect(rendered).to have_no_css(".yui-card-footer__center")
  end

  # Rewrite / the visibility control appearing for an authorized viewer is
  # RecordFooterComponent's own responsibility (see its spec); covered here
  # end-to-end via a signed-in session in
  # spec/requests/current_teams/memories_request_spec.rb and
  # spec/requests/teams/memories_request_spec.rb.
end
