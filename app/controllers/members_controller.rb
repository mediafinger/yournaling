class MembersController < ApplicationController
  def index
    authorize! current_user, to: :index?, with: MemberPolicy

    # members = authorized_scope(Member.all, type: :relation, as: :current_team_scope)

    @members = Member.includes(:user, :team).all
  end

  def show
    @member = Member.urlsafe_find!(params[:id])
    authorize! @member
  end

  def new
    @member = Member.new(team: current_team)
    authorize! @member
  end

  def edit
    @member = Member.urlsafe_find!(params[:id])
    authorize! @member
  end

  def create
    @member = Member.new(create_params)
    authorize! @member

    if @member.save
      redirect_to @member, notice: "Member was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @member = Member.urlsafe_find!(params[:id])
    authorize! @member

    if @member.update(update_params)
      redirect_to @member, notice: "Member was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @member = Member.urlsafe_find!(params[:id])
    authorize! @member

    @member.destroy!

    redirect_to members_url, notice: "Member was successfully destroyed."
  end

  private

  def create_params
    params.require(:member).permit(:user_yid, :team_yid, roles: [])
  end

  def update_params
    params.require(:member).permit(roles: [])
  end
end
