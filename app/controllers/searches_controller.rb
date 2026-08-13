# frozen_string_literal: true

class SearchesController < ApplicationController
  skip_verify_authorized only: %i[new create]

  SEARCHABLE_KLASSES = %w[Team Memory Location Picture Thought Weblink Member].freeze

  def new
    @klass_name = query_params[:klass_name].presence
    @query = query_params[:query].presence
    return if @query.blank? || @query.strip.length < 3 || @klass_name.blank?

    searchable_type = @klass_name if SEARCHABLE_KLASSES.include?(@klass_name)
    scope = { searchable_type: }.compact
    @results = PgSearch.multisearch(@query).where(**scope)
  end

  def create
    klass_name = query_params[:klass_name].presence
    query = query_params[:query].presence
    return redirect_to(new_search_url(klass_name:)) if query.blank? || query.strip.length < 3 || klass_name.blank?

    redirect_to new_search_url(query:, klass_name:)
  end

  private

  def query_params
    params.permit(:query, :klass_name)
  end
end
