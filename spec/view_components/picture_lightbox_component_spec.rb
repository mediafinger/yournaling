# frozen_string_literal: true

require "rails_helper"

RSpec.describe PictureLightboxComponent, type: :component do
  let(:team) { FactoryBot.create(:team) }
  let(:picture) { FactoryBot.create(:picture, team: team, name: "Matterhorn Peak", visibility: "published") }

  it "renders clickable thumbnail trigger and modal dialog" do
    rendered = render_inline(described_class.new(picture: picture, team: team))

    expect(rendered.to_html).to have_css("div[data-controller='modal']")
    expect(rendered.to_html).to have_css("[data-action='click->modal#open']")
    expect(rendered.to_html).to have_css("dialog[data-modal-target='dialog']")
    expect(rendered.to_html).to have_css("button[data-action='click->modal#close']")
  end

  it "renders picture details, enlarged image link, and open original button in new tab" do
    rendered = render_inline(described_class.new(picture: picture, team: team))

    expect(rendered.to_html).to include("Matterhorn Peak")
    expect(rendered.to_html).to have_link(
      "Open original in new tab ↗",
      href: "/teams/#{team.to_param}/pictures_only/#{picture.to_param}"
    )
    expect(rendered.to_html).to have_css(
      "a[href='/teams/#{team.to_param}/pictures_only/#{picture.to_param}'][target='_blank'][rel='noopener noreferrer']"
    )
  end

  context "when picture is unpublished in manage mode" do
    let(:unpublished_picture) { FactoryBot.create(:picture, team: team, name: "Secret Draft Photo", visibility: "draft") }

    it "renders link to blob storage in new tab" do
      rendered = render_inline(described_class.new(picture: unpublished_picture, team: team))

      expect(rendered.to_html).to include("Secret Draft Photo")
      expect(rendered.to_html).to have_css("a[target='_blank'][rel='noopener noreferrer']")
    end
  end
end
