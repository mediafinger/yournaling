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
      @team = Team.new(team_params)

      Team.create_with_history(record: @team, history_params: { team: nil, user: current_user, done_by_admin: true })

      if @team.persisted?
        redirect_to admin_team_url(@team), notice: "Team was successfully created."
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      @team = Team.urlsafe_find!(params[:id])
      @team.assign_attributes(team_params)

      Team.update_with_history(record: @team, history_params: { team: nil, user: current_user, done_by_admin: true })

      if @team.changed? # == team still dirty, not saved
        render :edit, status: :unprocessable_content
      else
        redirect_to admin_team_url(@team), notice: "Team was successfully updated."
      end
    end

    def destroy
      @team = Team.urlsafe_find!(params[:id])

      Team.destroy_with_history(record: @team, history_params: { team: nil, user: current_user, done_by_admin: true })

      redirect_to admin_teams_url, notice: "Team was successfully destroyed."
    end

    private

    def team_params
      params.expect(team: [:name])
    end
  end
end
