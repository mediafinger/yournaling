# frozen_string_literal: true

require "rails_helper"

RSpec.describe NavNewButtonComponent, type: :component do
  let(:team) { FactoryBot.create(:team, name: "Voyagers") }
  let(:user) { FactoryBot.create(:user, name: "Sam Explorer") }
  let(:member) { Member.create!(team: team, user: user, roles: %w[owner]) }

  context "when in browse mode as guest" do
    before do
      allow_any_instance_of(described_class).to receive(:current_user).and_return(User.new) # rubocop:disable RSpec/AnyInstance
      allow_any_instance_of(described_class).to receive(:current_team).and_return(nil) # rubocop:disable RSpec/AnyInstance
    end

    it "renders + New link to login" do
      rendered = render_inline(described_class.new(mode: :browse))
      expect(rendered.to_html).to have_link("+ New", href: "/login")
    end
  end

  context "when in browse mode as logged in user without team" do
    before do
      allow_any_instance_of(described_class).to receive(:current_user).and_return(user) # rubocop:disable RSpec/AnyInstance
      allow_any_instance_of(described_class).to receive(:current_team).and_return(nil) # rubocop:disable RSpec/AnyInstance
    end

    it "renders + New link to switch team" do
      rendered = render_inline(described_class.new(mode: :browse))
      expect(rendered.to_html).to have_link("+ New", href: "/switch_current_teams")
    end
  end

  context "when in browse mode as logged in user with team" do
    before do
      allow_any_instance_of(described_class).to receive(:current_user).and_return(user) # rubocop:disable RSpec/AnyInstance
      allow_any_instance_of(described_class).to receive(:current_team).and_return(team) # rubocop:disable RSpec/AnyInstance
    end

    it "renders + New dropdown for post types" do
      rendered = render_inline(described_class.new(mode: :browse))
      expect(rendered.to_html).to have_css("details.dropdown summary", text: "+ New")
      expect(rendered.to_html).to have_link("Memory", href: "/current_team/memories/new", visible: :all)
      expect(rendered.to_html).to have_link("Chronicle", href: "/current_team/chronicles/new", visible: :all)
    end
  end

  context "when in manage mode" do
    before do
      member
      allow_any_instance_of(described_class).to receive(:current_user).and_return(user) # rubocop:disable RSpec/AnyInstance
      allow_any_instance_of(described_class).to receive(:current_team).and_return(team) # rubocop:disable RSpec/AnyInstance
      allow_any_instance_of(described_class).to receive(:current_member).and_return(member) # rubocop:disable RSpec/AnyInstance
    end

    it "renders + New dropdown for posts, insights, and member" do
      rendered = render_inline(described_class.new(mode: :manage))
      expect(rendered.to_html).to have_css("details.dropdown summary", text: "+ New")
      expect(rendered.to_html).to have_link("Memory", href: "/current_team/memories/new", visible: :all)
      expect(rendered.to_html).to have_link("Picture", href: "/current_team/pictures/new", visible: :all)
      expect(rendered.to_html).to have_link("Member", href: "/current_team/members/new", visible: :all)
    end
  end

  context "when in admin mode" do
    let(:admin_user) { FactoryBot.create(:user, name: "Alice Admin", role: "admin") }

    before do
      allow_any_instance_of(described_class).to receive(:current_user).and_return(admin_user) # rubocop:disable RSpec/AnyInstance
    end

    it "renders + New dropdown for admin entities, posts, and insights" do
      rendered = render_inline(described_class.new(mode: :admin))
      expect(rendered.to_html).to have_css("details.dropdown summary", text: "+ New")
      expect(rendered.to_html).to have_link("Team", href: "/admin/teams/new", visible: :all)
      expect(rendered.to_html).to have_link("User", href: "/admin/users/new", visible: :all)
      expect(rendered.to_html).to have_link("Chronicle", href: "/admin/chronicles/new", visible: :all)
    end
  end
end
