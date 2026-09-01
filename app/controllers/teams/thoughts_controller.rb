# frozen_string_literal: true

module Teams
  class ThoughtsController < AppTeamsController
    def show
      @thought = record(Thought, params[:id])

      render "teams/thoughts/show"
    end
  end
end
