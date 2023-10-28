class TeamsController < ApplicationController
  def index
    authorize! current_user, to: :index?, with: TeamPolicy

    # teams = authorized_scope(Team.all, type: :relation, as: :current_team_scope)

    @teams = Team.all
  end

  def show
    @team = Team.urlsafe_find!(params[:id])
    authorize! @team
  end

  def new
    @team = Team.new
    authorize! @team
  end

  def edit
    @team = Team.urlsafe_find!(params[:id])
    authorize! @team
  end

  def create
    raise AuthError unless current_user.persisted?

    @team = Team.new(team_params)
    authorize! @team

    if @team.save
      Member.create!(team: @team, user: current_user, roles: Member::VALID_ROLES)
      switch_current_team(@team.yid)

      redirect_to @team, notice: "Team was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @team = Team.urlsafe_find!(params[:id])
    authorize! @team

    if @team.update(team_params)
      redirect_to @team, notice: "Team was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @team = Team.urlsafe_find!(params[:id])
    authorize! @team

    @team.destroy!

    redirect_to teams_url, notice: "Team was successfully destroyed."
  end

  private

  def team_params
    params.require(:team).permit(:name)
  end
end
