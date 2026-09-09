class SwitchCurrentTeamsController < ApplicationController
  def index
    authorize! current_user, to: :index?, with: CurrentTeamPolicy

    @current_user_teams = current_user.teams

    render template: "switch_current_teams/index"
  end

  def show
    @current_team = current_team # == Current.team # == current_user.teams.find_by(id: session[:team_id])
    authorize! @current_team, with: CurrentTeamPolicy

    if @current_team
      render partial: "teams/team", locals: { team: @current_team }
    else
      redirect_to switch_current_teams_url, notice: "No Team selected"
    end
  end

  def create
    @team = switch_current_team(current_team_params[:team_id])
    authorize! @team, with: CurrentTeamPolicy

    redirect_to @team, notice: "Team #{@team.name} selected"
  end

  def destroy
    authorize! current_team, with: CurrentTeamPolicy

    go_solo

    redirect_to root_url, notice: "No Team selected, going solo"
  end

  private

  def current_team_params
    params.expect(current_team: [:team_id])
  end
end
