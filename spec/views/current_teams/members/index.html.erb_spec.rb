# frozen_string_literal: true

require "rails_helper"

RSpec.describe "current_teams/members/index", type: :view do
  let(:members) { FactoryBot.create_list(:member, 2) }

  before do
    assign(:members, members)
  end

  it "renders a list of members" do
    render
    members.each do |member|
      expect(rendered).to match(/#{CGI.escapeHTML(member.user.name)}/)
      expect(rendered).to include("Roles")
    end
  end
end
