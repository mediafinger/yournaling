# frozen_string_literal: true

require "rails_helper"

RSpec.describe ContentVisibilityDropdownComponent, type: :component do
  let(:team) { FactoryBot.create(:team) }
  let(:user) { FactoryBot.create(:user) }
  let!(:member) { Member.create!(team: team, user: user, roles: %w[owner publisher]) }
  let(:chronicle) { FactoryBot.create(:chronicle, team: team, visibility: "internal") }

  it "renders dropdown with available visibility options" do
    rendered = render_inline(described_class.new(record: chronicle, user: user, team: team, member: member))

    expect(rendered.to_html).to include("details")
    expect(rendered.to_html).to include("dropdown")
    expect(rendered.to_html).to include("Change visibility")
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
