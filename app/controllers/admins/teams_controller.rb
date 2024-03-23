module Admins
  class TeamsController < AdminController
    def index
      @teams = Team.all
    end

    def show
      @team = Team.urlsafe_find!(params[:id])
    end

    def new
      @team = Team.new
    end

    def edit
      @team = Team.urlsafe_find!(params[:id])
    end

    def create
      raise AuthError unless current_user.persisted?

      @team = Team.new(team_params)

      Team.transaction do
        @team.save &&
          RecordHistoryService.call(
            record: @team, team: current_team, user: current_user, event: :created, done_by_admin: true)
      end

      if @team.persisted?
        redirect_to @team, notice: "Team was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      @team = Team.urlsafe_find!(params[:id])

      Team.transaction do
        @team.update(team_params) &&
          RecordHistoryService.call(
            record: @team, team: current_team, user: current_user, event: :updated, done_by_admin: true)
      end

      if @team.changed? # == team still dirty, not saved
        render :edit, status: :unprocessable_entity
      else
        redirect_to @team, notice: "Team was successfully updated."
      end
    end

    def destroy
      @team = Team.urlsafe_find!(params[:id])

      Team.transaction do
        RecordHistoryService.call(
          record: @team, team: current_team, user: current_user, event: :deleted, done_by_admin: true)
        @team.destroy!
      end

      redirect_to admin_teams_url, notice: "Team was successfully destroyed."
    end

    private

    def team_params
      params.require(:team).permit(:name)
    end
  end
end
