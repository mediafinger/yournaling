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

      if @member.save
        redirect_to admin_member_url(@member), notice: "Member was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      @member = Member.urlsafe_find!(params[:id])

      if @member.update(update_params)
        redirect_to admin_member_url(@member), notice: "Member was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @member = Member.urlsafe_find!(params[:id])

      @member.destroy!

      redirect_to admin_members_url, notice: "Member was successfully destroyed."
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
