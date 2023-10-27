class TeamsController < ApplicationController
  before_action :set_team, only: %i[show edit update destroy]

  # GET /teams
  def index
    raise AuthError unless current_user.persisted?

    @teams = Team.all
  end

  # GET /teams/1
  def show
  end

  # GET /teams/new
  def new
    raise AuthError unless current_user.persisted?

    @team = Team.new
  end

  # GET /teams/1/edit
  def edit
    raise AuthError unless @team == current_team && current_member.owner?
  end

  # POST /teams
  def create
    raise AuthError unless current_user.persisted?

    @team = Team.new(team_params)

    if @team.save
      member = Member.create!(team: @team, user: current_user, roles: Member::VALID_ROLES)
      switch_current_team(@team.yid)

      redirect_to @team, notice: "Team was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /teams/1
  def update
    raise AuthError unless @team == current_team && current_member.owner?

    if @team.update(team_params)
      redirect_to @team, notice: "Team was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /teams/1
  def destroy
    raise AuthError unless @team == current_team && current_member.owner?

    @team.destroy!

    redirect_to teams_url, notice: "Team was successfully destroyed."
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_team
    @team = Team.urlsafe_find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def team_params
    params.require(:team).permit(:name)
  end
end
