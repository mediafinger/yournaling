module Teams
  class StoriesController < AppTeamsController
    def show
      @story = record(Story, params[:id])

      render "teams/stories/show"
    end
  end
end
