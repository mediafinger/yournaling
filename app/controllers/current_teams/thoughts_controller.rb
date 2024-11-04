module CurrentTeams
  class ThoughtsController < AppCurrentTeamController
    skip_before_action :authenticate, only: %i[index show] # allow everyone to see the thoughts

    def index
      authorize! current_user, to: :index?, with: ThoughtPolicy

      # thoughts = authorized_scope(Thought.all, type: :relation, as: :current_team_scope)
      thoughts = Thought.all

      @thoughts = thoughts
    end

    def show
      @thought = Thought.urlsafe_find!(params[:id])
      authorize! @thought
    end

    def new
      @thought = Thought.new(team: current_team)
      authorize! @thought
    end

    def edit
      @thought = Thought.urlsafe_find!(params[:id])
      authorize! @thought
    end

    # TODO: set preview_snippet by calling the URL once to also validate it
    def create
      @thought = Thought.new(
        text: thought_params[:text],
        date: thought_params[:date],
        team: current_team
      )

      authorize! @thought

      Thought.create_with_history(record: @thought, history_params: { team: current_team, user: current_user })

      if @thought.persisted?
        redirect_to current_team_thought_url(@thought), notice: "Thought was successfully created."
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      @thought = Thought.urlsafe_find!(params[:id])
      authorize! @thought
      @thought.assign_attributes(thought_params)

      Thought.update_with_history(record: @thought, history_params: { team: current_team, user: current_user })

      if @thought.changed? # == thought still dirty, not saved
        render :edit, status: :unprocessable_content
      else
        redirect_to current_team_thought_url(@thought), notice: "Thought was successfully updated."
      end
    end

    def destroy
      @thought = Thought.urlsafe_find!(params[:id])
      authorize! @thought

      Thought.destroy_with_history(record: @thought, history_params: { team: current_team, user: current_user })

      redirect_to current_team_thoughts_url, notice: "Thought was successfully destroyed."
    end

    private

    def thought_params
      params.require(:thought).permit(:text, :date)
    end
  end
end
