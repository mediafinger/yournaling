module Admins
  class UsersController < AdminController
    def index
      @users = User.all
    end

    def show
      @user = User.urlsafe_find!(params[:id])
    end

    def new
      @user = User.new
    end

    def edit
      @user = User.urlsafe_find!(params[:id])
    end

    def create
      @user = User.new(create_params)

      User.transaction do
        @user.save &&
          RecordHistoryService.call(
            record: @user, team: current_team, user: current_user, event: :created, done_by_admin: true)
      end

      if @user.persisted?
        redirect_to @user, notice: "User was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      @user = User.urlsafe_find!(params[:id])

      User.transaction do
        @user.update(update_params) &&
          RecordHistoryService.call(
            record: @user, team: current_team, user: current_user, event: :updated, done_by_admin: true)
      end

      if @user.changed? # == user still dirty, not saved
        render :edit, status: :unprocessable_entity
      else
        redirect_to @user, notice: "User was successfully updated."
      end
    end

    def destroy
      @user = User.urlsafe_find!(params[:id])

      User.transaction do
        RecordHistoryService.call(
          record: @user, team: current_team, user: current_user, event: :deleted, done_by_admin: true)
        @user.destroy! # TODO: define what happens with uploaded content
      end

      redirect_to admin_users_url, notice: "User was successfully destroyed."
    end

    private

    # Only allow a list of trusted parameters through.
    def create_params
      params.require(:user).permit(:name, :email, :password)
    end

    def update_params
      params.require(:user).permit(:name, :nickname) # TODO: extract password & email update to extra endpoints
    end
  end
end
