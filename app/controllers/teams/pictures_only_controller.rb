module Teams
  class PicturesOnlyController < AppTeamsController
    def show
      @picture = record(Picture, params[:id])

      render "teams/pictures_only/show", layout: false
    end
  end
end
