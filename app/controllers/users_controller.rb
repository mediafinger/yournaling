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

    User.transaction do
      @user.save &&
        RecordHistoryService.call(record: @user, team: Team.new(yid: :none), user: @user, event: :created)
    end

    if @user.persisted?
      redirect_to @user, notice: "User was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    # raise AuthError unless @user == current_user && @user.persisted?
    @user = User.urlsafe_find!(params[:id])
    authorize! @user

    User.transaction do
      @user.update(update_params) &&
        RecordHistoryService.call(record: @user, team: Team.new(yid: :none), user: current_user, event: :updated)
    end

    if @user.changed? # == user still dirty, not saved
      render :edit, status: :unprocessable_entity
    else
      redirect_to @user, notice: "User was successfully updated."
    end
  end

  def destroy
    # raise AuthError unless @user == current_user && @user.persisted?
    @user = User.urlsafe_find!(params[:id])
    authorize! @user

    User.transaction do
      RecordHistoryService.call(record: @user, team: Team.new(yid: :none), user: current_user, event: :deleted)
      @user.destroy! # TODO: define what happens with uploaded content
    end

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
