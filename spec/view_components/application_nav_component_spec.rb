# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationNavComponent, type: :component do
  let(:team) { FactoryBot.create(:team) }
  let(:user) { FactoryBot.create(:user, role: "admin") }

  before do
    Member.create!(team: team, user: user, roles: %w[owner])
    allow_any_instance_of(described_class).to receive(:current_user).and_return(user) # rubocop:disable RSpec/AnyInstance
    allow_any_instance_of(described_class).to receive(:current_team).and_return(team) # rubocop:disable RSpec/AnyInstance
  end

  context "when in default scope" do
    before do
      allow_any_instance_of(described_class).to receive(:active_path?).and_return(false) # rubocop:disable RSpec/AnyInstance
    end

    it "renders admin link, current team link, logins link, and teams link" do
      rendered = render_inline(described_class.new)

      expect(rendered.to_html).to have_link("Go to Admin Area", href: "/admin")
      expect(rendered.to_html).to have_link("Go to Current Team", href: "/current_team")
      expect(rendered.to_html).to have_link("Logins", href: "/logins")
      expect(rendered.to_html).to have_link("Teams", href: "/teams")
    end
  end

  context "when in current_team scope" do
    before do
      allow_any_instance_of(described_class).to receive(:active_path?) do |_instance, path| # rubocop:disable RSpec/AnyInstance
        path == "/current_team"
      end
    end

    it "renders current team navigation links and search" do
      rendered = render_inline(described_class.new)

      expect(rendered.to_html).to have_link("Search", href: "/current_team/new_search")
      expect(rendered.to_html).to have_link("Memories", href: "/current_team/memories")
      expect(rendered.to_html).to have_link("Locations", href: "/current_team/locations")
      expect(rendered.to_html).to have_link("Pictures", href: "/current_team/pictures")
    end
  end
end
