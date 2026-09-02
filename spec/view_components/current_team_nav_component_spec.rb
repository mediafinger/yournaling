# frozen_string_literal: true

require "rails_helper"

RSpec.describe CurrentTeamNavComponent, type: :component do
  let(:team) { FactoryBot.create(:team, name: "Alpha Squad") }
  let(:user) { FactoryBot.create(:user, name: "Bob Member") }

  before do
    Member.create!(team: team, user: user, roles: %w[owner])
    allow_any_instance_of(ApplicationComponent).to receive(:current_user).and_return(user) # rubocop:disable RSpec/AnyInstance
    allow_any_instance_of(ApplicationComponent).to receive(:current_team).and_return(team) # rubocop:disable RSpec/AnyInstance
    allow_any_instance_of(ApplicationComponent).to receive(:active_path?).and_return(false) # rubocop:disable RSpec/AnyInstance
  end

  it "renders left zone brand, manage team button, and + New dropdown" do
    rendered = render_inline(described_class.new)

    expect(rendered.to_html).to have_link("🌐 Yournaling", href: "/")
    expect(rendered.to_html).to have_link("Manage Alpha Squad", href: "/current_team")
    expect(rendered.to_html).to have_css("details.yui-menu summary", text: "+ New")
  end

  it "renders center zone post and insight links with dropdown" do
    rendered = render_inline(described_class.new)

    expect(rendered.to_html).to have_link("Chronicles", href: "/current_team/chronicles")
    expect(rendered.to_html).to have_link("Memories", href: "/current_team/memories")
    expect(rendered.to_html).to have_css("details.yui-menu summary", text: "Insights")
    expect(rendered.to_html).to have_link("Pictures", href: "/current_team/pictures", visible: :all)
    expect(rendered.to_html).to have_link("Thoughts", href: "/current_team/thoughts", visible: :all)
    expect(rendered.to_html).to have_link("Locations", href: "/current_team/locations", visible: :all)
    expect(rendered.to_html).to have_link("Weblinks", href: "/current_team/weblinks", visible: :all)
  end

  it "renders members, search, switch team, and logout controls" do
    rendered = render_inline(described_class.new)

    expect(rendered.to_html).to have_link("Members", href: "/current_team/members")
    expect(rendered.to_html).to have_link("🔍 Search", href: "/current_team/new_search")
    expect(rendered.to_html).to have_link("Switch Team", href: "/switch_current_teams")
    expect(rendered.to_html).to have_link("👤 Bob Member", href: "/logins")
    expect(rendered.to_html).to have_link("Logout")
  end

  context "when user is an admin" do
    let(:user) { FactoryBot.create(:user, name: "Alice Admin", role: "admin") }

    it "renders admin area link" do
      rendered = render_inline(described_class.new)

      expect(rendered.to_html).to have_link("🛡️ Admin Area", href: "/admin")
    end
  end
end
