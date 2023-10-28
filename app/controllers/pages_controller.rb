class PagesController < ApplicationController
  skip_before_action :authenticate, only: %i[home error]
  skip_verify_authorized only: %i[home error] # TODO: home -> guest

  def home
    redirect_to pictures_path
  end

  def error
  end
end
