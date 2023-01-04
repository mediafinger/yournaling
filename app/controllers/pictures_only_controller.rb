class PicturesOnlyController < ApplicationController
  def show
    @picture = Picture.find(params[:id])

    render :show, layout: false
  end
end
