# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Picture Lightbox Modal", type: :system do
  include ActionView::RecordIdentifier

  let(:team) { FactoryBot.create(:team, name: "Photographers Club") }
  let(:picture) { FactoryBot.create(:picture, team: team, name: "Sunset on Mont Blanc", visibility: "published") }
  let!(:memory) do
    FactoryBot.create(
      :memory,
      team: team,
      memo: "Captured this stunning view right before descending.",
      picture: picture,
      visibility: "published"
    )
  end

  it "renders picture with lightbox modal trigger and displays enlarged picture with original link" do
    visit root_url

    within("article.memory-card[id='#{dom_id(memory)}']") do
      expect(page).to have_css("div[data-controller='modal']")
      expect(page).to have_css("[data-action='click->modal#open']")
      expect(page).to have_css("dialog[data-modal-target='dialog']")

      within("dialog[data-modal-target='dialog']") do
        expect(page).to have_text("Sunset on Mont Blanc")
        expect(page).to have_link(
          "Open original in new tab ↗",
          href: "/teams/#{team.to_param}/pictures_only/#{picture.to_param}"
        )
      end
    end
  end
end
