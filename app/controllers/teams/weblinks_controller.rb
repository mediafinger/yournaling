module Teams
  class WeblinksController < AppTeamsController
    def show
      @weblink = record(Weblink, params[:id])

      render "teams/weblinks/show"
    end
  end
end
