class UsersController < ApplicationController
  def index
    # raise AuthError unless current_user.persisted?
    authorize! current_user, to: :index?, with: UserPolicy

    # users = authorized_scope(User.all, type: :relation, as: :current_team_scope)

    @users = User.all
  end

  def show
    @user = User.urlsafe_find!(params[:id])
    authorize! @user
  end

  def new
    @user = User.new
    authorize! @user
  end

  def edit
    # raise AuthError unless @user == current_user && @user.persisted?
    @user = User.urlsafe_find!(params[:id])
    authorize! @user
  end

  def create
    @user = User.new(create_params)
    authorize! @user

    User.create_with_history(record: @user, history_params: { team: Team.new(yid: :none), user: @user })

    if @user.persisted?
      redirect_to @user, notice: "User was successfully created."
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    # raise AuthError unless @user == current_user && @user.persisted?
    @user = User.urlsafe_find!(params[:id])
    authorize! @user
    @user.assign_attributes(update_params)

    User.update_with_history(record: @user, history_params: { team: Team.new(yid: :none), user: current_user })

    if @user.changed? # == user still dirty, not saved
      render :edit, status: :unprocessable_content
    else
      redirect_to @user, notice: "User was successfully updated."
    end
  end

  def destroy
    # raise AuthError unless @user == current_user && @user.persisted?
    @user = User.urlsafe_find!(params[:id])
    authorize! @user

    User.destroy_with_history(record: @user, history_params: { team: Team.new(yid: :none), user: current_user })

    redirect_to users_url, notice: "User was successfully destroyed."
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
