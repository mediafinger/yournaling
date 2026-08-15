# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationNavComponent, type: :component do
  let(:team) { FactoryBot.create(:team, name: "Alpha Squad") }
  let(:user) { FactoryBot.create(:user, role: "admin") }

  before do
    Member.create!(team: team, user: user, roles: %w[owner]) if user&.persisted? && team
    allow_any_instance_of(described_class).to receive(:current_user).and_return(user) # rubocop:disable RSpec/AnyInstance
    allow_any_instance_of(described_class).to receive(:current_team).and_return(team) # rubocop:disable RSpec/AnyInstance
    allow_any_instance_of(described_class).to receive(:active_path?).and_return(false) # rubocop:disable RSpec/AnyInstance
  end

  context "when user is an admin with an active team" do
    it "renders admin link, link with team name, logins, and teams link" do
      rendered = render_inline(described_class.new)

      expect(rendered.to_html).to have_link("Admin Area", href: "/admin")
      expect(rendered.to_html).to have_link("Alpha Squad", href: "/current_team")
      expect(rendered.to_html).to have_link("Logins", href: "/logins")
      expect(rendered.to_html).to have_link("Teams", href: "/teams")
      expect(rendered.to_html).to have_link("Search", href: "/search")
    end
  end

  context "when user is a regular non-admin" do
    let(:user) { FactoryBot.create(:user, role: "user") }

    it "does not render admin area link" do
      rendered = render_inline(described_class.new)

      expect(rendered.to_html).to have_no_link("Admin Area", href: "/admin")
      expect(rendered.to_html).to have_link("Alpha Squad", href: "/current_team")
      expect(rendered.to_html).to have_link("Teams", href: "/teams")
      expect(rendered.to_html).to have_link("Search", href: "/search")
    end
  end

  context "when user has no active team" do
    before do
      allow_any_instance_of(described_class).to receive(:current_team).and_return(nil) # rubocop:disable RSpec/AnyInstance
    end

    it "does not render team button" do
      rendered = render_inline(described_class.new)

      expect(rendered.to_html).to have_no_link("Alpha Squad", href: "/current_team")
      expect(rendered.to_html).to have_link("Teams", href: "/teams")
      expect(rendered.to_html).to have_link("Search", href: "/search")
    end
  end

  context "when active path is a team page" do
    before do
      allow_any_instance_of(described_class).to receive(:params).and_return({ team_id: team.to_param }) # rubocop:disable RSpec/AnyInstance
      allow_any_instance_of(described_class).to receive(:active_path?).with("/teams/#{team.to_param}").and_return(true) # rubocop:disable RSpec/AnyInstance
    end

    it "renders team resource links including chronicles, memories, and members" do
      rendered = render_inline(described_class.new(params: { team_id: team.to_param }))

      expect(rendered.to_html).to have_link("Chronicles", href: "/teams/#{team.to_param}/chronicles")
      expect(rendered.to_html).to have_link("Memories", href: "/teams/#{team.to_param}/memories")
      expect(rendered.to_html).to have_link("Members", href: "/teams/#{team.to_param}/members")
    end
  end

  context "when user is not logged in" do
    let(:user) { User.new }

    before do
      allow_any_instance_of(described_class).to receive(:current_team).and_return(nil) # rubocop:disable RSpec/AnyInstance
    end

    it "does not render teams link or admin links and renders login" do
      rendered = render_inline(described_class.new)

      expect(rendered.to_html).to have_no_link("Admin Area", href: "/admin")
      expect(rendered.to_html).to have_no_link("Alpha Squad", href: "/current_team")
      expect(rendered.to_html).to have_no_link("Logins", href: "/logins")
      expect(rendered.to_html).to have_no_link("Teams", href: "/teams")
      expect(rendered.to_html).to have_link("Search", href: "/search")
      expect(rendered.to_html).to have_link("Login", href: "/login")
    end
  end
end
