# frozen_string_literal: true

# The search form: a query input (Stimulus-validated) + a record-type select.
class SearchFormComponent < ApplicationComponent
  attr_reader :url, :klass_options, :query, :selected_klass, :form_legend

  def initialize(url:, klass_options:, default_klass:, query: nil, klass_name: nil, form_legend: "Search")
    @url = url
    @klass_options = klass_options
    @query = query
    @selected_klass = klass_name.presence || default_klass
    @form_legend = form_legend
  end

  def submit_disabled?
    query.to_s.strip.length < 3
  end
end
