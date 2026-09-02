# frozen_string_literal: true

require "rails_helper"

RSpec.describe YuiFormBuilder do
  subject(:form) { described_class.new(:memory, memory, view, {}) }

  let(:memory) { Memory.new(memo: "hi") }
  let(:view) do
    ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil).tap do |v|
      def v.protect_against_forgery? = false
    end
  end

  def html(fragment)
    Capybara.string(fragment.to_s)
  end

  describe "#text_field" do
    it "renders a Yui::FieldComponent with the humanised label and the model value" do
      rendered = html(form.text_field(:memo))

      input = rendered.find("input.ex-input")
      expect(rendered).to have_css("label.ex-label[for='#{input[:id]}']", text: "Memo")
      expect(input.value).to eq("hi")
      expect(input[:name]).to eq("memory[memo]")
    end

    it "carries a hint through" do
      expect(html(form.text_field(:memo, hint: "Keep it short."))).to have_css(".ex-hint", text: "Keep it short.")
    end

    it "surfaces the model's validation error and marks the field invalid" do
      memory.valid?
      rendered = html(form.text_field(:memo))

      expect(rendered).to have_css(".ex-field--invalid")
      expect(rendered).to have_css(".ex-error", text: "is too short (minimum is 4 characters)")
      expect(rendered.find("input")[:"aria-invalid"]).to eq("true")
    end

    it "derives required from a presence validator on the attribute" do
      expect(html(form.text_field(:memo))).to have_css("input[required]")
      expect(html(form.text_field(:location_name))).to have_no_css("input[required]")
    end
  end

  describe "#text_area" do
    it "renders a textarea field" do
      expect(html(form.text_area(:memo))).to have_css("textarea.ex-textarea", text: "hi")
    end
  end

  describe "#select" do
    it "renders a select with the given choices and the current value selected" do
      memory.visibility = "published"
      rendered = html(form.select(:visibility, Memory::VISIBILITY_STATES))

      expect(rendered).to have_css(".ex-select-wrap select[name='memory[visibility]']")
      expect(rendered).to have_css("option[selected][value='published']")
    end

    it "accepts [label, value] pairs" do
      rendered = html(form.select(:visibility, [["Only me", "draft"], ["Everyone", "published"]]))

      expect(rendered).to have_css("option[value='draft']", text: "Only me")
    end

    it "prepends a blank option with include_blank" do
      rendered = html(form.select(:visibility, Memory::VISIBILITY_STATES, include_blank: true))

      expect(rendered).to have_css("select option:first-child[value='']")
    end

    it "renders a multiple select with a []-suffixed name and a blank hidden field" do
      allow(memory).to receive_messages(respond_to?: true, tags: %w[a c])
      rendered = html(form.select(:tags, %w[a b c], multiple: true))

      expect(rendered).to have_css("input[type='hidden'][name='memory[tags][]'][value='']", visible: :all)
      expect(rendered).to have_css("select[multiple][name='memory[tags][]']")
      expect(rendered).to have_css("option[selected][value='a']")
      expect(rendered).to have_css("option[selected][value='c']")
      expect(rendered).to have_no_css("option[selected][value='b']")
    end
  end

  describe "#collection_select" do
    it "maps a collection through value/text methods" do
      teams = [Team.new(name: "Coast Year"), Team.new(name: "Alps")]
      allow(teams[0]).to receive(:id).and_return(1)
      allow(teams[1]).to receive(:id).and_return(2)

      rendered = html(form.collection_select(:team_id, teams, :id, :name))

      expect(rendered).to have_css("option[value='1']", text: "Coast Year")
      expect(rendered).to have_css("option[value='2']", text: "Alps")
    end
  end

  describe "#check_box" do
    it "renders a Yui::ChoiceComponent plus the Rails hidden field" do
      rendered = html(form.check_box(:pinned, { label: "Pin it" }, "1", "0"))

      expect(rendered).to have_css("label.ex-choice input[type='checkbox'][name='memory[pinned]']")
      expect(rendered).to have_css("label.ex-choice", text: "Pin it")
      expect(rendered).to have_css("input[type='hidden'][name='memory[pinned]'][value='0']", visible: :all)
    end
  end

  describe "#submit" do
    it "renders a Yui::ButtonComponent of type submit" do
      expect(html(form.submit("Save memory"))).to have_button("Save memory", type: "submit", class: "ex-btn")
    end
  end

  it "falls through to the stock builder for un-overridden helpers" do
    expect(html(form.hidden_field(:memo))).to have_field("memory[memo]", type: "hidden", visible: :all)
  end
end
