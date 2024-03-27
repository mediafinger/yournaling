module CurrentTeams
  class PagesController < AppCurrentTeamController
    # TODO: make index to the team-board?!
    #
    def index
      authorize! current_team, to: :show?, with: CurrentTeamPolicy
    end
  end
end
