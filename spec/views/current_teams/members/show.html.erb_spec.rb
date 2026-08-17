# frozen_string_literal: true

require "rails_helper"

RSpec.describe "current_teams/members/show", type: :view do
  let(:member) { FactoryBot.create(:member) }

  before do
    assign(:member, member)
  end

  it "renders attributes in member article" do
    render
    expect(rendered).to match(/#{CGI.escapeHTML(member.user.name)}/)
    expect(rendered).to include("Roles")
    expect(rendered).to match(/#{member.roles.first}/)
  end
end
