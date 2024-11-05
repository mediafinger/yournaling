module CurrentTeams
  class SearchesController < ApplicationController
    def new
      authorize! current_user, to: :show?, with: CurrentTeamPolicy

      @klass_name = query_params[:klass_name].presence
      @query = query_params[:query].presence
      @results = params.to_unsafe_h[:results]
    end

    def create
      authorize! current_user, to: :show?, with: CurrentTeamPolicy

      klass_name = query_params[:klass_name].presence
      query = query_params[:query].presence

      # TODO: add date RANGE to search scope

      scope = { team_id: current_team.id, searchable_type: klass_name }.compact
      results = PgSearch.multisearch(query).where(**scope)

      redirect_to current_team_new_search_url(query:, klass_name:, results: results.as_json)
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
end
