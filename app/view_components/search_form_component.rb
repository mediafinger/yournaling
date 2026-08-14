# frozen_string_literal: true

class SearchFormComponent < ApplicationComponent
  slim_template <<~SLIM
    article
      = form_with(url: @url, method: :post, data: { controller: "search" }) do |form|
        fieldset
          h3
            legend = @form_legend
          div
            = form.label :query
            = form.text_field :query, value: @query, data: { search_target: "input", action: "input->search#validate" }, minlength: 3, required: true
          div
            = form.label :klass_name
            = form.select :klass_name, @klass_options, selected: @selected_klass
          div
            = form.submit "Search", data: { search_target: "submit" }, disabled: (@query.to_s.strip.length < 3)
  SLIM

  def initialize(url:, klass_options:, default_klass:, query: nil, klass_name: nil, form_legend: "Search")
    @url = url
    @klass_options = klass_options
    @default_klass = default_klass
    @query = query
    @klass_name = klass_name
    @selected_klass = klass_name.presence || default_klass
    @form_legend = form_legend
  end
end
