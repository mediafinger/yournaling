# frozen_string_literal: true

require "rails_helper"

RSpec.describe Example::FieldComponent, type: :component do
  it "renders a labelled text input by default" do
    rendered = render_inline(described_class.new(label: "Title", name: "memory[title]"))

    input = rendered.css("input.ex-input").first
    label = rendered.css("label.ex-label").first
    expect(label[:for]).to eq(input[:id])
    expect(label).to have_text("Title")
  end

  it "renders a textarea when as: :textarea" do
    rendered = render_inline(described_class.new(label: "Notes", name: "n", as: :textarea, value: "hi"))

    expect(rendered).to have_css("textarea.ex-textarea", text: "hi")
  end

  it "renders a select with options and the current value selected" do
    rendered = render_inline(
      described_class.new(label: "Visibility", name: "v", as: :select, value: "team",
        options: [%w[Private private], %w[Team team]])
    )

    expect(rendered).to have_css(".ex-select-wrap select.ex-select")
    expect(rendered).to have_css("option[selected][value='team']", text: "Team")
  end

  it "marks a required field on its label" do
    rendered = render_inline(described_class.new(label: "Title", name: "t", required: true))

    expect(rendered).to have_css("input[required]")
    expect(rendered).to have_css("label .ex-label__required")
  end

  describe "hint and error" do
    it "associates a hint via aria-describedby" do
      rendered = render_inline(described_class.new(label: "Notes", name: "n", hint: "Markdown is supported."))

      hint = rendered.css(".ex-hint").first
      expect(rendered.css("input").first[:"aria-describedby"]).to include(hint[:id])
    end

    it "flags an invalid field and links the error message" do
      rendered = render_inline(described_class.new(label: "Email", name: "email", error: "Looks incomplete."))

      input = rendered.css("input").first
      error = rendered.css(".ex-error").first
      expect(rendered).to have_css(".ex-field--invalid")
      expect(input[:"aria-invalid"]).to eq("true")
      expect(input[:"aria-describedby"]).to include(error[:id])
      expect(error).to have_text("Looks incomplete.")
    end
  end
end
