class UsersController < ApplicationController
  def index
    authorize! current_user, to: :index?, with: UserPolicy

    # users = authorized_scope(User.all, type: :relation, as: :current_team_scope)

    @users = User.all
  end

  def show
    @user = User.urlsafe_find!(params[:id])
    authorize! @user
  end

  def edit
    @user = User.urlsafe_find!(params[:id])
    authorize! @user
  end

  def update
    @user = User.urlsafe_find!(params[:id])
    authorize! @user
    @user.assign_attributes(update_params)

    User.update_with_event(record: @user, event_params: { team: Team.new(id: :none), user: current_user })

    if @user.changed? # == user still dirty, not saved
      render :edit, status: :unprocessable_content
    else
      redirect_to @user, notice: "User was successfully updated."
    end
  end

  def destroy
    @user = User.urlsafe_find!(params[:id])
    authorize! @user

    User.destroy_with_event(record: @user, event_params: { team: Team.new(id: :none), user: current_user })

    redirect_to users_url, notice: "User was successfully destroyed."
  end

  private

  def update_params
    params.expect(user: %i[name nickname]) # TODO: extract password & email update to extra endpoints
  end
end
