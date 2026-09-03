# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Stories", type: :system do
  let(:user) { FactoryBot.create(:user, email: "writer@example.com", name: "Sam Scribe") }
  let(:team) { FactoryBot.create(:team, name: "Storytellers") }
  let!(:member) { Member.create!(team: team, user: user, roles: %w[owner]) }

  before do
    visit login_url
    fill_in :email, with: user.email
    fill_in :password, with: "foobar1234"
    click_button "Login"
    visit_switch_current_team(team)
  end

  it "creates a story through the Marksmith editor and renders its Markdown" do
    visit new_current_team_story_url

    expect(page).to have_css('[data-controller="marksmith list-continuation"]')

    fill_in "story[name]", with: "The Long Way North"
    fill_in "story[content]", with: "## Chapter One\n\nThe engine coughed twice, then **caught**."
    click_button "Create Story"

    expect(page).to have_text("Story was successfully created.")
    expect(page).to have_css("h2", text: "Chapter One")
    expect(page).to have_css(".yui-prose strong", text: "caught")

    story = Story.find_by!(name: "The Long Way North")
    expect(story.content).to eq("## Chapter One\n\nThe engine coughed twice, then **caught**.")
  end

  it "attaches an existing story to a chronicle and renders it in the timeline" do
    story = FactoryBot.create(:story, team: team, name: "Prologue", content: "Where it all began, on a rainy Tuesday.")

    visit new_current_team_chronicle_url
    fill_in "chronicle[name]", with: "The Great Loop"
    fill_in "chronicle[notice]", with: "A season on the road, told in chapters and photographs."
    fill_in "chronicle[start_date]", with: Date.current.to_s

    form = find("form[action='#{current_team_chronicles_path}']")
    if Capybara.current_driver == :rack_test
      form.native.add_child("<input type='hidden' name='chronicle[entry_ids][]' value='#{story.id}' />")
    end
    click_button "Create Chronicle"

    expect(page).to have_text("Chronicle was successfully created.")
    chronicle = Chronicle.find_by!(name: "The Great Loop")
    expect(chronicle.stories).to contain_exactly(story)

    visit current_team_chronicle_url(chronicle.urlsafe_id)
    expect(page).to have_text("Prologue")
    expect(page).to have_text("Where it all began, on a rainy Tuesday.")
  end
end
