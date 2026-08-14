# frozen_string_literal: true

class SearchesController < ApplicationController
  include Searchable

  skip_verify_authorized only: %i[new create]

  SEARCHABLE_KLASSES = %w[Team Memory Location Picture Thought Weblink Member].freeze

  def new
    @klass_name = query_params[:klass_name].presence
    @query = query_params[:query].presence
    return unless valid_search_params?(@query, @klass_name)

    @results = perform_search(@query, @klass_name)
  end

  def create
    klass_name = query_params[:klass_name].presence
    query = query_params[:query].presence
    return redirect_to(new_search_url(klass_name:)) unless valid_search_params?(query, klass_name)

    redirect_to new_search_url(query:, klass_name:)
  end
end
