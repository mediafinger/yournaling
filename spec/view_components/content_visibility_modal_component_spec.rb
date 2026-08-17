# frozen_string_literal: true

require "rails_helper"

RSpec.describe ContentVisibilityModalComponent, type: :component do
  let(:team) { FactoryBot.create(:team) }
  let(:user) { FactoryBot.create(:user) }
  let!(:member) { Member.create!(team: team, user: user, roles: %w[owner publisher]) }
  let(:chronicle) { FactoryBot.create(:chronicle, team: team, visibility: "internal") }

  it "renders icon-button with action to open modal dialog" do
    rendered = render_inline(described_class.new(record: chronicle, user: user, team: team, member: member))

    expect(rendered.to_html).to have_css("div[data-controller='modal']")
    expect(rendered.to_html).to have_css("button[data-action='click->modal#open'][aria-label='Change visibility']")
    expect(rendered.to_html).to have_css("dialog[data-modal-target='dialog']")
    expect(rendered.to_html).to have_css("button[data-action='click->modal#close'][aria-label='Close']")
  end

  it "renders modal dialog with available visibility options and highlighted active status" do
    rendered = render_inline(described_class.new(record: chronicle, user: user, team: team, member: member))

    expect(rendered.to_html).to include("dialog")
    expect(rendered.to_html).to include("Change Visibility")
    expect(rendered.to_html).to include("Draft")
    expect(rendered.to_html).to include("Internal ✓")
    expect(rendered.to_html).to include("Published")
    expect(rendered.to_html).to include("Archived")
    expect(rendered.to_html).not_to include("turbo_confirm")
    expect(rendered.to_html).not_to include("Cancel")
  end

  it "renders modal dialog for a draft record" do
    draft_chronicle = FactoryBot.create(:chronicle, team: team, visibility: "draft")
    rendered = render_inline(described_class.new(record: draft_chronicle, user: user, team: team, member: member))

    expect(rendered.to_html).to have_css("button[data-action='click->modal#open'][aria-label='Change visibility']")
    expect(rendered.to_html).to include("Draft ✓")
    expect(rendered.to_html).to include("Internal")
    expect(rendered.to_html).to include("Published")
    expect(rendered.to_html).to include("Archived")
  end

  it "does not render when user has no update permission" do
    editor_user = FactoryBot.create(:user)
    editor_member = Member.create!(team: team, user: editor_user, roles: %w[editor])
    # An editor cannot update a published chronicle (only publisher can)
    published_chronicle = FactoryBot.create(:chronicle, team: team, visibility: "published")

    rendered = render_inline(described_class.new(record: published_chronicle, user: editor_user, team: team,
      member: editor_member))
    expect(rendered.to_html).to be_blank
  end
end
