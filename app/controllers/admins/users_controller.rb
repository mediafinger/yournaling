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

      if @user.save
        redirect_to admin_user_url(@user), notice: "User was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      @user = User.urlsafe_find!(params[:id])

      if @user.update(update_params)
        redirect_to admin_user_url(@user), notice: "User was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @user = User.urlsafe_find!(params[:id])

      @user.delete # TODO: define what happens with uploaded content

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
