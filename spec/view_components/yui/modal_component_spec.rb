# frozen_string_literal: true

require "rails_helper"

RSpec.describe Yui::ModalComponent, type: :component do
  def render_modal(**, &block)
    render_inline(described_class.new(**)) do |m|
      m.with_trigger { "Open".html_safe }
      block&.call(m)
      "Body".html_safe
    end
  end

  it "renders a <dialog> wired to the yui-modal controller with a trigger and body" do
    rendered = render_modal(title: "Change visibility")

    expect(rendered).to have_css(".ex-modal-wrap[data-controller='yui-modal']")
    expect(rendered).to have_css(".ex-modal__trigger[data-action='click->yui-modal#open']", text: "Open")
    expect(rendered).to have_css("dialog.ex-modal[data-yui-modal-target='dialog']", visible: :all)
    expect(rendered).to have_css(".ex-modal__body", text: "Body", visible: :all)
  end

  it "labels the dialog from its title and renders a close button" do
    rendered = render_modal(title: "Change visibility")

    dialog = rendered.css("dialog").first
    title = rendered.css(".ex-modal__title").first
    expect(dialog[:"aria-labelledby"]).to eq(title[:id])
    expect(rendered).to have_css(".ex-modal__close[aria-label='Close'][data-action='click->yui-modal#close']", visible: :all)
  end

  it "omits the header when there is no title and dismissible: false" do
    rendered = render_modal(dismissible: false)

    expect(rendered).to have_no_css(".ex-modal__header")
  end

  it "maps size to a modifier class" do
    expect(render_modal(size: :lg)).to have_css("dialog.ex-modal--lg", visible: :all)
  end

  it "renders a footer slot" do
    rendered = render_modal { |m| m.with_footer { "Save".html_safe } }

    expect(rendered).to have_css("footer.ex-modal__footer", text: "Save", visible: :all)
  end
end
