class LoginsController < ApplicationController
  def index
    authorize! current_user, to: :index?, with: LoginPolicy

    @logins = current_user.logins.order(updated_at: :desc)
  end

  def destroy
    @login = Login.find(params[:id])
    authorize! @login

    @login.destroy!

    redirect_to login_records_url, notice: "Login information was successfully destroyed."
  end
end
