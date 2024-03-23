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

    Member.transaction do
      @member.save &&
        RecordHistoryService.call(record: @member, team: current_team, user: current_user, event: :created)
    end

    if @member.persisted?
      redirect_to @member, notice: "Member was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @member = Member.urlsafe_find!(params[:id])
    authorize! @member

    Member.transaction do
      @member.update(update_params) &&
        RecordHistoryService.call(record: @member, team: current_team, user: current_user, event: :updated)
    end

    if @member.changed? # == member still dirty, not saved
      render :edit, status: :unprocessable_entity
    else
      redirect_to @member, notice: "Member was successfully updated."
    end
  end

  def destroy
    @member = Member.urlsafe_find!(params[:id])
    authorize! @member

    Member.transaction do
      RecordHistoryService.call(record: @member, team: current_team, user: current_user, event: :deleted)
      @member.destroy!
    end

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
