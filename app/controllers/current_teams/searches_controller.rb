# frozen_string_literal: true

module CurrentTeams
  class SearchesController < AppCurrentTeamController
    include Searchable

    SEARCHABLE_KLASSES = %w[Memory Location Picture Thought Weblink Member].freeze

    def new
      authorize! current_user, to: :show?, with: CurrentTeamPolicy

      @klass_name = query_params[:klass_name].presence
      @query = query_params[:query].presence
      return unless valid_search_params?(@query, @klass_name)

      @results = perform_search(@query, @klass_name, additional_scope: { team_id: current_team.id })
    end

    def create
      authorize! current_user, to: :show?, with: CurrentTeamPolicy

      klass_name = query_params[:klass_name].presence
      query = query_params[:query].presence
      return redirect_to(current_team_new_search_url(klass_name:)) unless valid_search_params?(query, klass_name)

      # TODO: add date RANGE to search scope

      redirect_to current_team_new_search_url(query:, klass_name:)
    end
  end
end
