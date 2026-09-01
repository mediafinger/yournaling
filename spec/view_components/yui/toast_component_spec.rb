# frozen_string_literal: true

require "rails_helper"

RSpec.describe Yui::ToastComponent, type: :component do
  it "renders the message with a live-region role and a dismiss control" do
    rendered = render_inline(described_class.new("Memory saved", variant: :success))

    expect(rendered).to have_css("div.ex-toast.ex-toast--success[role='status'] p.ex-toast__body", text: "Memory saved")
    expect(rendered).to have_css("button.ex-toast__dismiss[aria-label='Dismiss'][data-action='yui-toast#dismiss']")
    expect(rendered).to have_css("[data-controller='yui-toast'][data-yui-toast-delay-value]")
  end

  it "uses an assertive alert for the danger variant" do
    rendered = render_inline(described_class.new("Gone wrong", variant: :danger))

    expect(rendered).to have_css(".ex-toast--danger[role='alert'][aria-live='assertive']")
  end

  it "maps a Rails flash key to a variant" do
    expect(described_class::FLASH_VARIANTS.fetch("alert")).to eq(:danger)
    expect(described_class::FLASH_VARIANTS.fetch("notice")).to eq(:success)
  end
end
