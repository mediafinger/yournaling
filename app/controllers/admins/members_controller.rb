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
      cleaned_params = create_params
      cleaned_params[:roles] = cleaned_params[:roles].compact_blank
      @member = Member.new(cleaned_params)

      Member.create_with_history(record: @member, history_params: { team: nil, user: current_user, done_by_admin: true })

      if @member.persisted?
        redirect_to admin_member_url(@member), notice: "Member was successfully created."
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      @member = Member.urlsafe_find!(params[:id])
      @member.assign_attributes(update_params)

      Member.update_with_history(record: @member, history_params: { team: nil, user: current_user, done_by_admin: true })

      if @member.changed? # == member still dirty, not saved
        render :edit, status: :unprocessable_content
      else
        redirect_to admin_member_url(@member), notice: "Member was successfully updated."
      end
    end

    def destroy
      @member = Member.urlsafe_find!(params[:id])

      Member.destroy_with_history(record: @member, history_params: { team: nil, user: current_user, done_by_admin: true })

      redirect_to admin_members_url, notice: "Member was successfully destroyed."
    end

    private

    def create_params
      params.require(:member).permit(:user_id, :team_id, roles: [])
    end

    def update_params
      params.require(:member).permit(roles: [])
    end
  end
end
