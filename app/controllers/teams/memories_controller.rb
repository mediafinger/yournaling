module Teams
  class MemoriesController < AppTeamsController
    def index
      @memories = records_scope(Memory.with_includes)
    end

    def show
      @memory = record(Memory.with_includes, params[:id])
    end
  end
end
