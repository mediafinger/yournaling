# frozen_string_literal: true

class SearchesController < ApplicationController
  skip_verify_authorized only: %i[new create]

  SEARCHABLE_KLASSES = %w[Memory Location Picture Thought Weblink Member].freeze

  def new
    @klass_name = query_params[:klass_name].presence
    @query = query_params[:query].presence
    @results = params.to_unsafe_h[:results]
  end

  def create
    klass_name = query_params[:klass_name].presence
    query = query_params[:query].presence

    scope = { searchable_type: (klass_name if SEARCHABLE_KLASSES.include?(klass_name)) }.compact
    results = query.present? ? PgSearch.multisearch(query).where(**scope) : []

    redirect_to new_search_url(query:, klass_name:, results: results.as_json)
  end

  private

  def query_params
    params.permit(
      :query,
      :klass_name,
      results: %i[id content searchable_type searchable_id team_id created_at updated_at]
    )
  end
end
