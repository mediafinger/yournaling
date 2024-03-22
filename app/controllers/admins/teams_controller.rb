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

      if @team.save
        redirect_to admin_team_url(@team), notice: "Team was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      @team = Team.urlsafe_find!(params[:id])

      if @team.update(team_params)
        redirect_to admin_team_url(@team), notice: "Team was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @team = Team.urlsafe_find!(params[:id])

      @team.destroy!

      redirect_to admin_teams_url, notice: "Team was successfully destroyed."
    end

    private

    def team_params
      params.require(:team).permit(:name)
    end
  end
end
