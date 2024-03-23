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

    Team.transaction do
      @team.save &&
        RecordHistoryService.call(record: @team, team: @team, user: current_user, event: :created)
    end

    if @team.persisted?
      member = Member.new(team: @team.reload, user: current_user, roles: Member::VALID_ROLES)

      Member.transaction do
        member.save &&
          RecordHistoryService.call(record: member, team: @team, user: current_user, event: :created)
      end

      switch_current_team(@team.yid)

      redirect_to @team, notice: "Team was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @team = Team.urlsafe_find!(params[:id])
    authorize! @team

    Team.transaction do
      @team.update(team_params) &&
        RecordHistoryService.call(record: @team, team: current_team, user: current_user, event: :updated)
    end

    if @team.changed? # == team still dirty, not saved
      render :edit, status: :unprocessable_entity
    else
      redirect_to @team, notice: "Team was successfully updated."
    end
  end

  def destroy
    @team = Team.urlsafe_find!(params[:id])
    authorize! @team

    Team.transaction do
      RecordHistoryService.call(record: @team, team: current_team, user: current_user, event: :deleted)
      @team.destroy!
    end

    redirect_to teams_url, notice: "Team was successfully destroyed."
  end

  private

  def team_params
    params.require(:team).permit(:name)
  end
end
