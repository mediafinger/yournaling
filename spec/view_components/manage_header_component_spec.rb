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
  let(:memory) { FactoryBot.create(:memory, team: team, memo: "A sunny day", visibility: "published") }
  let(:thought) do
    FactoryBot.create(:thought, team: team, text: "A deep thought", date: "2024-05-01", visibility: "internal")
  end
  let(:location) { FactoryBot.create(:location, team: team, name: "City Plaza", date: "2024-06-01", visibility: "internal") }
  let(:picture) { FactoryBot.create(:picture, team: team, name: "Sunset View", date: "2024-07-01", visibility: "internal") }
  let(:weblink) { FactoryBot.create(:weblink, team: team, name: "Trail Guide", date: "2024-08-01", visibility: "internal") }

  it "renders chronicle header with title, dates, visibility, and action buttons" do
    rendered = render_inline(described_class.new(record: chronicle, user: user, team: team, member: member))

    expect(rendered.to_html).to have_css("h3", text: "Desert Journey")
    expect(rendered.to_html).to include("Dates: </strong>2024-01-01 – 2024-01-10")
    expect(rendered.to_html).to include("Visibility:&nbsp;</strong>internal")
    expect(rendered.to_html).to have_link("Open", href: "/current_team/chronicles/#{chronicle.to_param}")
    expect(rendered.to_html).to have_link("Rewrite", href: "/current_team/chronicles/#{chronicle.to_param}/edit")
  end

  it "renders memory header with title, date, visibility, and action buttons" do
    rendered = render_inline(described_class.new(record: memory, user: user, team: team, member: member))

    expect(rendered.to_html).to have_css("h4", text: "Memory")
    expect(rendered.to_html).to include("Date: </strong>#{memory.created_at.to_date}")
    expect(rendered.to_html).to include("Visibility:&nbsp;</strong>published")
    expect(rendered.to_html).to have_link("Open", href: "/current_team/memories/#{memory.to_param}")
    expect(rendered.to_html).to have_link("Rewrite", href: "/current_team/memories/#{memory.to_param}/edit")
  end

  it "renders member header with user name, member since date, visibility, and action buttons" do
    rendered = render_inline(described_class.new(record: member, user: user, team: team, member: member))

    expect(rendered.to_html).to have_css("h4", text: user.name)
    expect(rendered.to_html).to include("Member since: </strong>#{member.created_at.to_date}")
    expect(rendered.to_html).to include("Visibility:&nbsp;</strong>published")
    expect(rendered.to_html).to have_link("Open", href: "/current_team/members/#{member.to_param}")
    expect(rendered.to_html).to have_link("Rewrite", href: "/current_team/members/#{member.to_param}/edit")
  end

  it "renders insight header (thought, location, picture, weblink)" do
    [thought, location, picture, weblink].each do |insight|
      rendered = render_inline(described_class.new(record: insight, user: user, team: team, member: member))

      expect(rendered.to_html).to have_css("h4")
      expect(rendered.to_html).to include("Visibility:&nbsp;</strong>internal")
      expect(rendered.to_html).to have_link("Open")
      expect(rendered.to_html).to have_link("Rewrite")
    end
  end

  it "suppresses action buttons when hide_actions is true" do
    rendered = render_inline(described_class.new(record: thought, user: user, team: team, member: member,
      hide_actions: true))

    expect(rendered.to_html).to have_no_link("Open")
    expect(rendered.to_html).to have_no_link("Rewrite")
    expect(rendered.to_html).to have_no_css("dialog")
  end
end
