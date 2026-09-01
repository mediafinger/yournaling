# frozen_string_literal: true

require "rails_helper"

RSpec.describe Yui::ChoiceComponent, type: :component do
  it "wraps the input in its label so the whole row is clickable" do
    rendered = render_inline(described_class.new("Make public", name: "visibility"))

    expect(rendered).to have_css("label.ex-choice > input[type='checkbox'][name='visibility']")
    expect(rendered).to have_css("label.ex-choice", text: "Make public")
  end

  it "renders a radio when type: :radio" do
    rendered = render_inline(described_class.new("Team only", name: "v", type: :radio, value: "team"))

    expect(rendered).to have_css("input[type='radio'][value='team']")
  end

  it "renders helper text" do
    rendered = render_inline(described_class.new("Comments", name: "c", hint: "You can turn this off later."))

    expect(rendered).to have_css(".ex-choice__text small", text: "You can turn this off later.")
  end

  it "reflects checked and disabled state" do
    rendered = render_inline(described_class.new("X", name: "x", checked: true, disabled: true))

    expect(rendered).to have_css("input[checked][disabled]")
  end
end
