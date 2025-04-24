module CurrentTeams
  class MemoriesController < AppCurrentTeamController
    def index
      authorize! current_user, to: :index?, with: MemoryPolicy

      # memories = authorized_scope(Memory.all, type: :relation, as: :current_team_scope)

      @memories = Memory.includes(:team, :picture, :location, :weblink).all
    end

    def show
      @memory = Memory.urlsafe_find!(params[:id])
      authorize! @memory
    end

    def new
      @memory = Memory.new(team: current_team)
      authorize! @memory
    end

    def edit
      @memory = Memory.urlsafe_find!(params[:id])
      authorize! @memory
    end

    def create
      @memory = Memory.new(create_params.compact_blank.merge(team: current_team))
      authorize! @memory

      Memory.create_with_history(record: @memory, history_params: { team: current_team, user: current_user })

      if @memory.persisted?
        redirect_to current_team_memory_url(@memory), notice: "Memory was successfully created."
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      @memory = Memory.urlsafe_find!(params[:id])
      authorize! @memory
      @memory.assign_attributes(update_params.compact_blank)

      Memory.update_with_history(record: @memory, history_params: { team: current_team, user: current_user })

      if @memory.changed? # == memory still dirty, not saved
        render :edit, status: :unprocessable_content
      else
        redirect_to current_team_memory_url(@memory), notice: "Memory was successfully updated."
      end
    end

    def destroy
      @memory = Memory.urlsafe_find!(params[:id])
      authorize! @memory

      Memory.destroy_with_history(record: @memory, history_params: { team: current_team, user: current_user })

      redirect_to current_team_memories_url, notice: "Memory was successfully destroyed."
    end

    private

    def create_params
      params.expect(memory: %i[team_id memo picture_id location_id weblink_id])
    end

    def update_params
      params.expect(memory: %i[memo picture_id location_id weblink_id])
    end
  end
end
