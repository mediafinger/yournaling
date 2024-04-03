module CurrentTeams
  class PagesController < AppCurrentTeamController
    # TODO: make show the team-board?!
    #
    def show
      authorize! current_team, to: :show?, with: CurrentTeamPolicy
    end
  end
end
