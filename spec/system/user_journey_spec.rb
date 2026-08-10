# frozen_string_literal: true

require "rails_helper"

RSpec.describe "User Journey: Sign in, switch team, upload photo, create memory, and view timeline", type: :system do
  let(:user) { FactoryBot.create(:user, email: "traveler@example.com", name: "Alex Nomad") }
  let(:team) { FactoryBot.create(:team, name: "Wild Vanlifers") }
  let!(:member) { Member.create!(team: team, user: user, roles: %w[owner]) }

  it "completes the full journey seamlessly" do
    # 1. Sign In
    visit login_url
    fill_in :email, with: user.email
    fill_in :password, with: "foobar1234"
    click_button "Login"

    expect(page).to have_current_path("/", ignore_query: true)
    expect(page).to have_button("Logout Alex Nomad")

    # 2. Switch Team
    visit_switch_current_team(team)
    expect(page).to have_current_path("/teams/#{team.urlsafe_id}", ignore_query: true)

    # 3. Upload Photo
    visit new_current_team_picture_url
    attach_file "picture[file]", Rails.root.join("spec/support/macbookair_stickered.jpg")
    fill_in "picture[name]", with: "Sierra Nevada Ridge"
    click_button "Create Picture"

    expect(page).to have_text("Picture was successfully created.")
    expect(page).to have_text("Sierra Nevada Ridge")

    # 4. Create Memory with Photo
    visit new_current_team_memory_url
    fill_in "memory[memo]", with: "Wild camping at 2000m with breathtaking sunset views over the valley"
    select "Sierra Nevada Ridge", from: "memory[picture_id]"
    click_button "Create Memory"

    expect(page).to have_text("Memory was successfully created.")
    expect(page).to have_text("Wild camping at 2000m with breathtaking sunset views over the valley")

    # 5. View Timeline
    visit current_team_memories_url
    expect(page).to have_css("#memories")
    expect(page).to have_text("Wild camping at 2000m with breathtaking sunset views over the valley")
    expect(page).to have_text("Sierra Nevada Ridge")
    expect(page).to have_text("Wild Vanlifers")
  end
end
