# frozen_string_literal: true

# Form builder that renders each field through `Yui::FieldComponent` (and
# check boxes through `Yui::ChoiceComponent`) so a form picks up the design
# language without touching its markup.
#
# Opt in per form during the migration (TODO_UI_DESIGN.md Phase 1):
#
#   = form_with model: @memory, builder: YuiFormBuilder do |form|
#     = form.text_field :title, hint: "Keep it short."
#     = form.text_area  :memo
#     = form.select     :visibility, Memory::VISIBILITY_STATES
#     = form.check_box  :pinned, label: "Pin to the top"
#     = form.submit
#
# Everything not overridden here falls through to the stock Rails builder, so a
# half-converted form still works.
class YuiFormBuilder < ActionView::Helpers::FormBuilder
  INPUT_TYPES = {
    date_field: "date",
    email_field: "email",
    number_field: "number",
    password_field: "password",
    search_field: "search",
    telephone_field: "tel",
    text_field: "text",
    url_field: "url",
  }.freeze

  INPUT_TYPES.each do |helper, input_type|
    define_method(helper) do |method, options = {}|
      yui_field(method, options, as: :input, type: input_type)
    end
  end

  def text_area(method, options = {})
    yui_field(method, options, as: :textarea)
  end

  # `choices` accepts what Rails `options_for_select` does at its simplest:
  # an array of strings or of [label, value] pairs, or a Hash.
  def select(method, choices = nil, options = {}, html_options = {})
    yui_field(method, options.merge(html_options), as: :select, choices: normalize_choices(choices))
  end

  def collection_select(method, collection, value_method, text_method, options = {}, html_options = {})
    pairs = collection.map { |item| [item.public_send(text_method), item.public_send(value_method)] }
    yui_field(method, options.merge(html_options), as: :select, choices: pairs)
  end

  def check_box(method, options = {}, checked_value = "1", unchecked_value = "0")
    label = options.delete(:label) || object_label(method)
    @template.render(Yui::ChoiceComponent.new(
      label, name: field_name(method), type: :checkbox, value: checked_value,
      hint: options.delete(:hint), checked: field_value(method).to_s == checked_value.to_s,
      disabled: options[:disabled] || false
    )) + hidden_field(method, value: unchecked_value, id: nil)
  end

  def submit(value = nil, options = {})
    value ||= submit_default_value
    @template.render(Yui::ButtonComponent.new(value, type: "submit", variant: options.delete(:variant) || :primary))
  end

  private

  def yui_field(method, options, as:, type: "text", choices: [])
    options = options.symbolize_keys
    @template.render(Yui::FieldComponent.new(
      label: options[:label] || object_label(method),
      name: field_name(method),
      as:, type:,
      value: options.key?(:value) ? options[:value] : field_value(method),
      placeholder: options[:placeholder],
      hint: options[:hint],
      error: field_error(method),
      required: options.fetch(:required, required_field?(method)),
      disabled: options[:disabled] || false,
      options: choices,
      rows: options[:rows] || 4
    ))
  end

  def object_label(method)
    if object.respond_to?(:class) && object.class.respond_to?(:human_attribute_name)
      object.class.human_attribute_name(method)
    else
      method.to_s.humanize
    end
  end

  def field_value(method)
    object.respond_to?(method) ? object.public_send(method) : nil
  end

  def field_error(method)
    return nil unless object.respond_to?(:errors) && object.errors.respond_to?(:[])

    object.errors[method].first
  end

  # Best-effort: presence validators on the attribute mean "required".
  def required_field?(method)
    return false unless object.respond_to?(:class) && object.class.respond_to?(:validators_on)

    object.class.validators_on(method).any?(ActiveModel::Validations::PresenceValidator)
  end

  def normalize_choices(choices)
    case choices
    when Hash then choices.to_a
    else Array(choices)
    end
  end
end
