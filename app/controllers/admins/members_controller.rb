module Admins
  class MembersController < AdminController
    def index
      @members = Member.includes(:user, :team).all
    end

    def show
      @member = Member.urlsafe_find!(params[:id])
    end

    def new
      @member = Member.new(team: current_team)
    end

    def edit
      @member = Member.urlsafe_find!(params[:id])
    end

    def create
      @member = Member.new(create_params)

      Member.transaction do
        @member.save &&
          RecordHistoryService.call(
            record: @member, team: current_team, user: current_user, event: :created, done_by_admin: true)
      end

      if @member.persisted?
        redirect_to @member, notice: "Member was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      @member = Member.urlsafe_find!(params[:id])

      Member.transaction do
        @member.update(update_params) &&
          RecordHistoryService.call(
            record: @member, team: current_team, user: current_user, event: :updated, done_by_admin: true)
      end

      if @member.changed? # == member still dirty, not saved
        render :edit, status: :unprocessable_entity
      else
        redirect_to @member, notice: "Member was successfully updated."
      end
    end

    def destroy
      @member = Member.urlsafe_find!(params[:id])

      Member.transaction do
        RecordHistoryService.call(
          record: @member, team: current_team, user: current_user, event: :deleted, done_by_admin: true)
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
end
