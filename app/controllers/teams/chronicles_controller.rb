module Teams
  class ChroniclesController < AppTeamsController
    def index
      @chronicles = records_scope(Chronicle.with_includes)

      render "teams/chronicles/index"
    end

    def show
      @chronicle = record(Chronicle.with_includes, params[:id])

      render "teams/chronicles/show"
    end
  end
end
