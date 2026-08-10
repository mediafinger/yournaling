# frozen_string_literal: true

require "rails_helper"

RSpec.describe TeamSwitcherComponent, type: :component do
  context "when user is logged in" do
    let(:user) { FactoryBot.create(:user, name: "Andy Camper") }
    let(:team) { FactoryBot.create(:team) }

    before do
      Member.create!(team: team, user: user, roles: %w[owner])
      allow_any_instance_of(described_class).to receive(:current_user).and_return(user) # rubocop:disable RSpec/AnyInstance
    end

    it "renders switch team link and logout button" do
      rendered = render_inline(described_class.new)

      expect(rendered.to_html).to have_link("Switch team", href: "/switch_current_teams")
      expect(rendered.to_html).to have_button("Logout Andy Camper")
    end
  end

  context "when user is not logged in (guest)" do
    let(:guest_user) { User.new }

    before do
      allow_any_instance_of(described_class).to receive(:current_user).and_return(guest_user) # rubocop:disable RSpec/AnyInstance
    end

    it "renders login link" do
      rendered = render_inline(described_class.new)

      expect(rendered.to_html).to have_link("Login", href: "/login")
    end
  end
end
