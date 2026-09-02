# frozen_string_literal: true

module CurrentTeams
  class PagesController < AppCurrentTeamController
    def show
      authorize! current_team, to: :show?, with: CurrentTeamPolicy

      @pagy, @team_artefacts = pagy(
        :offset,
        authorized_scope(TeamArtefact.chronological, type: :relation).includes(:team, artefact: %i[team])
      )
      # @newest_at is the feed cursor: the timestamp the `feed-refresh` controller
      # polls `check_newer` with. Named the same in both feed controllers (here it
      # tracks `updated_at`, in PagesController `republished_at`).
      @newest_at = @team_artefacts.first&.updated_at&.iso8601(6) || Time.current.iso8601(6)
    end

    def check_newer
      authorize! current_team, to: :show?, with: CurrentTeamPolicy
      since_time = parse_since_param
      newer_scope = authorized_scope(TeamArtefact.where("updated_at > ?", since_time).chronological, type: :relation)

      render json: {
        count: newer_scope.count,
        latest_at: newer_scope.first&.updated_at&.iso8601(6),
      }
    end

    def newer
      authorize! current_team, to: :show?, with: CurrentTeamPolicy
      since_time = parse_since_param
      newer_scope = TeamArtefact.where("updated_at > ?", since_time).chronological
      @team_artefacts = authorized_scope(newer_scope, type: :relation).includes(:team, artefact: %i[team])
      @newest_at = @team_artefacts.first&.updated_at&.iso8601(6) || params[:since]

      render layout: false
    end

    private

    def parse_since_param
      params[:since].present? ? Time.zone.parse(params[:since]) : Time.current
    end
  end
end
