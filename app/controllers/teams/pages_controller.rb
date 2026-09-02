# frozen_string_literal: true

module Teams
  class PagesController < AppTeamsController
    # The public "team home" — `GET /teams/:team_id` — a timeline scoped to this
    # team's published stories and memories, the browse-mode counterpart of the
    # central home feed (PagesController#show).
    def show
      @pagy, @publishings = pagy(
        :offset,
        Publishing.published.where(team:).reorder(republished_at: :desc).includes(:team, post: %i[team])
      )
    end
  end
end
