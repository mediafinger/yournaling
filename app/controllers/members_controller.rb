class MembersController < ApplicationController
  before_action :set_member, only: %i[show edit update destroy]

  # GET /members
  def index
    @members = Member.includes(:user, :team).recent
  end

  # GET /members/1
  def show
  end

  # GET /members/new
  def new
    @member = Member.new
  end

  # GET /members/1/edit
  def edit
  end

  # POST /members
  def create
    @member = Member.new(member_params)

    if @member.save
      redirect_to @member, notice: "Member was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /members/1
  def update
    if @member.update(member_params)
      redirect_to @member, notice: "Member was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /members/1
  def destroy
    @member.destroy
    redirect_to members_url, notice: "Member was successfully destroyed."
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_member
    @member = Member.urlsafe_find(params[:id])
  end

  # TODO: roles handling broken / move to extra endpoint - or add specific logic to create and update
  # Only allow a list of trusted parameters through. // TODO: dry-validation / dry-contract ?!
  def member_params
    params.require(:member).permit(:user_yid, :team_yid, :roles)
  end
end
