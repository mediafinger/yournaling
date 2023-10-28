class UsersController < ApplicationController
  skip_verify_authorized # TODO: REMOVE!
  before_action :set_user, only: %i[show edit update destroy]

  # GET /users
  def index
    raise AuthError unless current_user.persisted?

    @users = User.all
  end

  # GET /users/1
  def show
  end

  # TODO: move to a sign_up page?!
  # GET /users/new
  def new
    @user = User.new
  end

  # GET /users/1/edit
  def edit
    raise AuthError unless @user == current_user && @user.persisted?
  end

  # TODO: move to a sign_up page?!
  # POST /users
  def create
    @user = User.new(user_params)

    if @user.save
      redirect_to @user, notice: "User was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /users/1
  def update
    raise AuthError unless @user == current_user && @user.persisted?

    if @user.update(user_params)
      redirect_to @user, notice: "User was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # TODO: move to close account page
  # DELETE /users/1
  def destroy
    raise AuthError unless @user == current_user && @user.persisted?

    @user.delete # TODO: define what happens with uploaded content

    redirect_to users_url, notice: "User was successfully destroyed."
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_user
    @user = User.urlsafe_find!(params[:id])
  end

  # TODO: extract user#password handling to extra endpoint
  # Only allow a list of trusted parameters through.
  def user_params
    params.require(:user).permit(:name, :email, :password)
  end
end
