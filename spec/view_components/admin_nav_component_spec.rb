# frozen_string_literal: true

require "rails_helper"

RSpec.describe AdminNavComponent, type: :component do
  let(:admin_user) { FactoryBot.create(:user, name: "Alice Admin", role: "admin") }

  before do
    allow_any_instance_of(ApplicationComponent).to receive(:current_user).and_return(admin_user) # rubocop:disable RSpec/AnyInstance
    allow_any_instance_of(ApplicationComponent).to receive(:active_path?).and_return(false) # rubocop:disable RSpec/AnyInstance
  end

  it "renders left zone admin brand and exit link" do
    rendered = render_inline(described_class.new)

    expect(rendered.to_html).to have_link("🛡️ Admin Area", href: "/admin")
    expect(rendered.to_html).to have_link("⬅ Exit Admin", href: "/")
  end

  it "renders center zone users, teams, and post links" do
    rendered = render_inline(described_class.new)

    expect(rendered.to_html).to have_link("Users", href: "/admin/users")
    expect(rendered.to_html).to have_link("Teams", href: "/admin/teams")
    expect(rendered.to_html).to have_link("Members", href: "/admin/members")
    expect(rendered.to_html).to have_link("Chronicles", href: "/admin/chronicles")
    expect(rendered.to_html).to have_link("Memories", href: "/admin/memories")
  end

  it "renders insight audit dropdown, ops tools, scope to team, and logout" do
    rendered = render_inline(described_class.new)

    expect(rendered.to_html).to have_css("details.dropdown summary", text: "Insights")
    expect(rendered.to_html).to have_link("Pictures", href: "/admin/pictures", visible: :all)
    expect(rendered.to_html).to have_link("Record Events", href: "/admin/record_events")
    expect(rendered.to_html).to have_link("Analytics", href: "/admin/blazer")
    expect(rendered.to_html).to have_link("Jobs", href: "/admin/jobs")
    expect(rendered.to_html).to have_css(".scope-to-team", text: "Scope to Team")
    expect(rendered.to_html).to have_link("👤 Alice Admin", href: "/logins")
    expect(rendered.to_html).to have_link("Logout")
  end
end
