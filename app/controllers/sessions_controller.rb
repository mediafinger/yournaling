class SessionsController < ApplicationController
  skip_before_action :authenticate, only: %i[new create]

  def new
    render :new
  end

  def create
    user = User.authenticate_by(email: login_params[:email], password: login_params[:password])

    if user.present?
      session[:user_id] = user.urlsafe_id
      redirect_to session.delete(:return_to) || root_path, notice: "Login successful" # TODO: notice shown, but pointless
    else
      render :new, status: :forbidden, notice: "Login failed, please try again" # TODO: notice not shown
    end
  end

  def destroy
    session.clear

    redirect_to root_path
  end

  private

  def login_params
    params.permit(:email, :password)
  end
end
