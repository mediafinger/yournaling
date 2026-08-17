# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Content Visibility Modal Dialog", type: :system do
  let(:user) { FactoryBot.create(:user, email: "publisher@example.com", name: "Morgan Publisher") }
  let(:team) { FactoryBot.create(:team, name: "Publishing Team") }
  let!(:member) { Member.create!(team: team, user: user, roles: %w[owner publisher]) }

  let!(:chronicle) { FactoryBot.create(:chronicle, team: team, name: "Alpine Trail", visibility: "internal") }
  let!(:picture) { FactoryBot.create(:picture, team: team, name: "Mountain Sunrise", visibility: "internal") }

  before do
    visit login_url
    fill_in :email, with: user.email
    fill_in :password, with: "foobar1234"
    click_button "Login"
    visit_switch_current_team(team)
  end

  it "renders the visibility icon-button and allows changing visibility on a draft chronicle" do
    draft_chronicle = FactoryBot.create(:chronicle, team: team, name: "Draft Expedition", visibility: "draft")
    visit current_team_chronicle_url(draft_chronicle.urlsafe_id)

    expect(page).to have_text("Visibility: draft")
    expect(page).to have_button("Change visibility")
    expect(page).to have_css("dialog[data-modal-target='dialog']", visible: :all)

    dialog = find("dialog[data-modal-target='dialog']", visible: :all)
    expect(dialog).to have_button("Draft ✓", disabled: true)
    expect(dialog).to have_button("Internal")
    expect(dialog).to have_button("Published")
    expect(dialog).to have_button("Archived")

    find_button("Published", visible: :all).click

    expect(page).to have_text("Chronicle was successfully updated.")
    expect(page).to have_text("Visibility: published")
    expect(draft_chronicle.reload.visibility).to eq("published")
  end

  it "renders the visibility icon-button that connects to the modal dialog on chronicle view" do
    visit current_team_chronicle_url(chronicle.urlsafe_id)

    expect(page).to have_text("Visibility: internal")
    expect(page).to have_button("Change visibility")
    expect(page).to have_css("div[data-controller='modal']")
    expect(page).to have_css("button[data-action='click->modal#open'][aria-label='Change visibility']")
    expect(page).to have_css("dialog[data-modal-target='dialog']", visible: :all)

    dialog = find("dialog[data-modal-target='dialog']", visible: :all)
    expect(dialog).to have_text("Change Visibility")
    expect(dialog).to have_button("Draft")
    expect(dialog).to have_button("Internal ✓", disabled: true)
    expect(dialog).to have_button("Published")
    expect(dialog).to have_button("Archived")
    expect(dialog).to have_no_button("Cancel")

    find_button("Published", visible: :all).click

    expect(page).to have_text("Chronicle was successfully updated.")
    expect(page).to have_text("Visibility: published")
    expect(chronicle.reload.visibility).to eq("published")
  end

  it "renders the modal dialog on insight show view and allows updating visibility" do
    visit current_team_picture_url(picture.urlsafe_id)

    expect(page).to have_text("Visibility: internal")
    expect(page).to have_button("Change visibility")
    expect(page).to have_css("button[data-action='click->modal#open'][aria-label='Change visibility']")
    expect(page).to have_css("dialog[data-modal-target='dialog']", visible: :all)

    find_button("Published", visible: :all).click

    expect(page).to have_text("Picture was successfully updated.")
    expect(page).to have_text("Visibility: published")
    expect(picture.reload.visibility).to eq("published")
  end

  it "renders the modal dialog on member show view and allows updating visibility" do
    visit current_team_member_url(member.urlsafe_id)

    expect(page).to have_text("Visibility: published")
    expect(page).to have_button("Change visibility")
    expect(page).to have_css("button[data-action='click->modal#open'][aria-label='Change visibility']")
    expect(page).to have_css("dialog[data-modal-target='dialog']", visible: :all)

    find_button("Internal", visible: :all).click

    expect(page).to have_text("Member was successfully updated.")
    expect(page).to have_text("Visibility: internal")
    expect(member.reload.visibility).to eq("internal")
  end
end
