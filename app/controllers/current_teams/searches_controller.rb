# frozen_string_literal: true

module CurrentTeams
  class SearchesController < AppCurrentTeamController
    SEARCHABLE_KLASSES = %w[Memory Location Picture Thought Weblink Member].freeze

    def new
      authorize! current_user, to: :show?, with: CurrentTeamPolicy

      @klass_name = query_params[:klass_name].presence
      @query = query_params[:query].presence
      return if @query.blank? || @query.strip.length < 3 || @klass_name.blank?

      searchable_type = @klass_name if SEARCHABLE_KLASSES.include?(@klass_name)
      scope = { team_id: current_team.id, searchable_type: }.compact
      @results = PgSearch.multisearch(@query).where(**scope)
    end

    def create
      authorize! current_user, to: :show?, with: CurrentTeamPolicy

      klass_name = query_params[:klass_name].presence
      query = query_params[:query].presence
      if query.blank? || query.strip.length < 3 || klass_name.blank?
        return redirect_to(current_team_new_search_url(klass_name:))
      end

      # TODO: add date RANGE to search scope

      redirect_to current_team_new_search_url(query:, klass_name:)
    end

    private

    def query_params
      params.permit(:query, :klass_name)
    end
  end
end
