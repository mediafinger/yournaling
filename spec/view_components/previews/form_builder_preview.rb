# frozen_string_literal: true

# @label Form (YuiFormBuilder)
#
# `form_with(builder: YuiFormBuilder)` routes every field through
# `Yui::FieldComponent` / `Yui::ChoiceComponent`, so a form picks up the
# design language without per-field markup.
# See `app/form_builders/yui_form_builder.rb`.
class FormBuilderPreview < ViewComponent::Preview
  def playground
    render_with_template
  end

  def with_errors
    render_with_template
  end
end
