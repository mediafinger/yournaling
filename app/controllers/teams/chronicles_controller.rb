# frozen_string_literal: true

module Teams
  class ChroniclesController < AppTeamsController
    def index
      @chronicles = records_scope(Chronicle.all)

      render "teams/chronicles/index"
    end

    def show
      @chronicle = record(Chronicle, params[:id])

      render "teams/chronicles/show"
    end
  end
end
