class SessionsController < ApplicationController
  skip_before_action :authenticate, only: %i[new create destroy] # allowing destroy means no harm
  skip_verify_authorized only: %i[new create destroy]

  def new
    render :new
  end

  def create
    user = sign_in(email: login_params[:email], password: login_params[:password])

    if user.present?
      redirect_to session.delete(:return_to) || root_path, notice: "Login successful" # TODO: notice shown, but pointless
    else
      render :new, status: :forbidden, notice: "Login failed, please try again" # TODO: notice not shown
    end
  end

  def destroy
    sign_out

    redirect_to root_path
  end

  private

  def login_params
    params.permit(:email, :password)
  end
end
