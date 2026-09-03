# frozen_string_literal: true

require "rails_helper"

RSpec.describe ManageHeaderComponent, type: :component do
  let(:team) { FactoryBot.create(:team) }
  let(:user) { FactoryBot.create(:user) }
  let!(:member) { Member.create!(team: team, user: user, roles: %w[owner publisher]) }

  let(:chronicle) do
    FactoryBot.create(:chronicle, team: team, name: "Desert Journey", start_date: "2024-01-01", end_date: "2024-01-10",
      visibility: "internal")
  end
  let(:memory) { FactoryBot.create(:memory, team: team, memo: "A sunny day by the shore", visibility: "published") }
  let(:thought) do
    FactoryBot.create(:thought, team: team, text: "A deep and meandering thought about tides", visibility: "internal")
  end
  let(:location) { FactoryBot.create(:location, team: team, name: "City Plaza", visibility: "internal") }
  let(:picture) { FactoryBot.create(:picture, team: team, name: "Sunset View", visibility: "internal") }
  let(:weblink) { FactoryBot.create(:weblink, team: team, name: "Trail Guide", visibility: "internal") }

  it "renders the chronicle name as an h4 with Open, Rewrite and a visibility button — no date, no 'Visibility:' label" do
    rendered = render_inline(described_class.new(record: chronicle, user: user, team: team, member: member))

    expect(rendered.to_html).to have_css("h4.yui-record-header__title", text: "Desert Journey")
    expect(rendered.to_html).to have_link("Open", href: "/current_team/chronicles/#{chronicle.to_param}")
    expect(rendered.to_html).to have_link("Rewrite", href: "/current_team/chronicles/#{chronicle.to_param}/edit")
    expect(rendered.to_html).to have_css("button[aria-label='Change visibility']", text: "Internal")
    expect(rendered.to_html).not_to include("Visibility:")
    expect(rendered.to_html).not_to include("2024-01-01")
  end

  it "renders the truncated memo as the memory title" do
    rendered = render_inline(described_class.new(record: memory, user: user, team: team, member: member))

    expect(rendered.to_html).to have_css("h4.yui-record-header__title", text: "A sunny day by the shore")
    expect(rendered.to_html).to have_css("button[aria-label='Change visibility']", text: "Published")
  end

  it "renders the member's user name as the title" do
    rendered = render_inline(described_class.new(record: member, user: user, team: team, member: member))

    expect(rendered.to_html).to have_css("h4.yui-record-header__title", text: user.name)
    expect(rendered.to_html).to have_link("Open", href: "/current_team/members/#{member.to_param}")
    expect(rendered.to_html).to have_link("Rewrite", href: "/current_team/members/#{member.to_param}/edit")
  end

  it "renders the truncated text as the thought title" do
    rendered = render_inline(described_class.new(record: thought, user: user, team: team, member: member))

    expect(rendered.to_html).to have_css("h4.yui-record-header__title", text: "A deep and meandering thought about tides")
  end

  it "renders an h4 title, Open, Rewrite and a visibility button for each insight type" do
    [location, picture, weblink].each do |insight|
      rendered = render_inline(described_class.new(record: insight, user: user, team: team, member: member))

      expect(rendered.to_html).to have_css("h4.yui-record-header__title")
      expect(rendered.to_html).to have_link("Open")
      expect(rendered.to_html).to have_link("Rewrite")
      expect(rendered.to_html).to have_css("button[aria-label='Change visibility']", text: "Internal")
    end
  end

  it "renders a static visibility badge (no modal) when the user may not change visibility" do
    editor = FactoryBot.create(:user)
    editor_member = Member.create!(team: team, user: editor, roles: %w[editor])
    published = FactoryBot.create(:chronicle, team: team, visibility: "published")

    rendered = render_inline(described_class.new(record: published, user: editor, team: team, member: editor_member))

    expect(rendered.to_html).to have_css(".yui-badge", text: "Published")
    expect(rendered.to_html).to have_no_css("button[aria-label='Change visibility']")
    expect(rendered.to_html).to have_no_css("dialog")
  end

  it "renders in a guest context (no user/member) without raising" do
    expect { render_inline(described_class.new(record: chronicle, team: team)) }.not_to raise_error
  end

  it "suppresses actions and the visibility control when hide_actions is true" do
    rendered = render_inline(described_class.new(record: thought, user: user, team: team, member: member,
      hide_actions: true))

    expect(rendered.to_html).to have_no_link("Open")
    expect(rendered.to_html).to have_no_link("Rewrite")
    expect(rendered.to_html).to have_no_css("dialog")
    expect(rendered.to_html).to have_no_css(".yui-badge")
  end
end
