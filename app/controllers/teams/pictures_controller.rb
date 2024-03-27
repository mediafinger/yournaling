module Teams
  class PicturesController < AppTeamsController
    def show
      @picture = record(Picture, params[:id])

      render "teams/pictures/show"
    end
  end
end
