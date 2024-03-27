module Teams
  class MemoriesController < AppTeamsController
    def index
      @memories = records_scope(Memory.with_includes)

      render "teams/memories/index"
    end

    def show
      @memory = record(Memory.with_includes, params[:id])

      render "teams/memories/show"
    end
  end
end
