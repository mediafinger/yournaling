class PicturesOnlyController < ApplicationController
  def show
    @picture = Picture.urlsafe_find(params[:id])

    render :show, layout: false
  end
end
