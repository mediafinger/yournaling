class PicturesOnlyController < ApplicationController
  def show
    @picture = Picture.urlsafe_find!(params[:id])
    authorize! @picture, to: :show?, with: PicturePolicy

    render :show, layout: false
  end
end
