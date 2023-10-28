class PicturesOnlyController < ApplicationController
  skip_verify_authorized # TODO: REMOVE!

  def show
    @picture = Picture.urlsafe_find!(params[:id])

    render :show, layout: false
  end
end
