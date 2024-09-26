module CurrentTeams
  class MemoriesController < AppCurrentTeamController
    def index
      authorize! current_user, to: :index?, with: MemoryPolicy

      # memories = authorized_scope(Memory.all, type: :relation, as: :current_team_scope)

      @memories = current_team_scope(Memory).includes(:team, :picture, :location, :weblink).all
    end

    def show
      @memory = current_team_scope(Memory).urlsafe_find!(params[:id])
      authorize! @memory
    end

    def new
      @memory = Memory.new(team: current_team)
      authorize! @memory
    end

    def edit
      @memory = current_team_scope(Memory).urlsafe_find!(params[:id])
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
      @memory = current_team_scope(Memory).urlsafe_find!(params[:id])
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
      @memory = current_team_scope(Memory).urlsafe_find!(params[:id])
      authorize! @memory

      Memory.destroy_with_history(record: @memory, history_params: { team: current_team, user: current_user })

      redirect_to current_team_memories_url, notice: "Memory was successfully destroyed."
    end

    private

    def create_params
      params.require(:memory).permit(:memo, :picture_yid, :location_yid, :weblink_yid)
    end

    def update_params
      params.require(:memory).permit(
        :memo, :picture_yid, :location_yid, :weblink_yid,
        location_attributes: %i[address country_code name lat long url], # accepts_nested_attributes_for
        picture_attributes: %i[file date name], # accepts_nested_attributes_for
        weblink_attributes: %i[url name description] # accepts_nested_attributes_for
      )
    end
  end
end
