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

      User.create_with_history(record: @user, history_params: { team: nil, user: current_user, done_by_admin: true })

      if @user.persisted?
        redirect_to admin_user_url(@user), notice: "User was successfully created."
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      @user = User.urlsafe_find!(params[:id])
      @user.assign_attributes(update_params)

      User.update_with_history(record: @user, history_params: { team: nil, user: current_user, done_by_admin: true })

      if @user.changed? # == user still dirty, not saved
        render :edit, status: :unprocessable_content
      else
        redirect_to admin_user_url(@user), notice: "User was successfully updated."
      end
    end

    def destroy
      @user = User.urlsafe_find!(params[:id])

      User.destroy_with_history(record: @user, history_params: { team: nil, user: current_user, done_by_admin: true })

      redirect_to admin_users_url, notice: "User was successfully destroyed."
    end

    private

    # Only allow a list of trusted parameters through.
    def create_params
      params.expect(user: %i[name email password])
    end

    def update_params
      params.expect(user: %i[name nickname]) # TODO: extract password & email update to extra endpoints
    end
  end
end
