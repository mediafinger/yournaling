# frozen_string_literal: true

require "rails_helper"

RSpec.describe CurrentTeamNavComponent, type: :component do
  let(:team) { FactoryBot.create(:team, name: "Alpha Squad") }
  let(:user) { FactoryBot.create(:user) }

  before do
    Member.create!(team: team, user: user, roles: %w[owner])
    allow_any_instance_of(described_class).to receive(:current_user).and_return(user) # rubocop:disable RSpec/AnyInstance
    allow_any_instance_of(described_class).to receive(:current_team).and_return(team) # rubocop:disable RSpec/AnyInstance
    allow_any_instance_of(described_class).to receive(:active_path?).and_return(false) # rubocop:disable RSpec/AnyInstance
  end

  it "renders browse mode exit link, current team name, and search" do
    rendered = render_inline(described_class.new)

    expect(rendered.to_html).to have_link("Browse Mode", href: "/")
    expect(rendered.to_html).to have_link("Alpha Squad", href: "/current_team")
    expect(rendered.to_html).to have_link("Search", href: "/current_team/new_search")
  end

  it "renders all resource navigation links" do
    rendered = render_inline(described_class.new)

    expect(rendered.to_html).to have_link("Memories", href: "/current_team/memories")
    expect(rendered.to_html).to have_link("Thoughts", href: "/current_team/thoughts")
    expect(rendered.to_html).to have_link("Pictures", href: "/current_team/pictures")
    expect(rendered.to_html).to have_link("Locations", href: "/current_team/locations")
    expect(rendered.to_html).to have_link("Weblinks", href: "/current_team/weblinks")
    expect(rendered.to_html).to have_link("Members", href: "/current_team/members")
  end
end
