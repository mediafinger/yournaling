module Admins
  class ThoughtsController < AdminController
    def index
      @thoughts = Thought.all
    end

    def show
      @thought = Thought.urlsafe_find!(params[:id])
    end

    def new
      @thought = Thought.new(team: current_team)
    end

    def edit
      @thought = Thought.urlsafe_find!(params[:id])
    end

    # TODO: set preview_snippet by calling the URL once to also validate it
    def create
      @thought = Thought.new(thought_params)

      Thought.create_with_history(record: @thought, history_params: { team: nil, user: current_user, done_by_admin: true })

      if @thought.persisted?
        redirect_to admin_thought_url(@thought), notice: "Thought was successfully created."
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      @thought = Thought.urlsafe_find!(params[:id])
      @thought.assign_attributes(thought_params)

      Thought.update_with_history(record: @thought, history_params: { team: nil, user: current_user, done_by_admin: true })

      if @thought.changed? # == thought still dirty, not saved
        render :edit, status: :unprocessable_content
      else
        redirect_to admin_thought_url(@thought), notice: "Thought was successfully updated."
      end
    end

    def destroy
      @thought = Thought.urlsafe_find!(params[:id])

      Thought.destroy_with_history(record: @thought, history_params: { team: nil, user: current_user, done_by_admin: true })

      redirect_to admin_thoughts_url, notice: "Thought was successfully destroyed."
    end

    private

    def thought_params
      params.require(:thought).permit(:text, :date, :team_id)
    end
  end
end
