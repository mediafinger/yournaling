class CurrentTeamsController < ApplicationController
  # GET /user/teams
  def index
    @current_teams = current_user.teams

    render template: "current_teams/index"
  end

  def show
    @current_team = current_team # == Current.team # == current_user.teams.find_by(yid: session[:team_yid])

    if @current_team
      render partial: "teams/team", locals: { team: @current_team }
    else
      redirect_to current_teams_url, notice: "No Team selected"
    end
  end

  # POST /user/teams
  def create
    @team = current_user.teams.find_by!(yid: current_team_params[:team_yid])

    session[:team_yid] = @team.yid
    initialize_request_context # to refresh the Current objects directly

    redirect_to @team, notice: "Team #{@team.name} selected"
  end

  private

  def current_team_params
    params.require(:current_team).permit(:team_yid)
  end
end
