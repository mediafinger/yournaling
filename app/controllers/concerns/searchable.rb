# frozen_string_literal: true

module Searchable
  extend ActiveSupport::Concern

  private

  def query_params
    params.permit(:query, :klass_name)
  end

  def valid_search_params?(query, klass_name)
    query.present? && query.strip.length >= 3 &&
      klass_name.present? && self.class::SEARCHABLE_KLASSES.include?(klass_name)
  end

  def perform_search(query, klass_name, additional_scope: {})
    scope = { searchable_type: klass_name }.merge(additional_scope)
    PgSearch.multisearch(query).includes(:searchable).where(**scope)
  end
end
