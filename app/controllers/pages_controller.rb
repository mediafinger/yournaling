class PagesController < ApplicationController
  skip_before_action :authenticate, only: %i[show]
  skip_verify_authorized only: %i[show]

  def show
  end
end
