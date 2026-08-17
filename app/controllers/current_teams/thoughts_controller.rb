# frozen_string_literal: true

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

      create_with_event(record: @thought)

      respond_to do |format|
        if @thought.persisted?
          format.html { redirect_to current_team_thought_url(@thought), notice: "Thought was successfully created." }
          format.json do
            render json: { id: @thought.id, text: @thought.text.truncate(60), type: "thought" }, status: :created
          end
        else
          format.html { render :new, status: :unprocessable_content }
          format.json { render json: { errors: @thought.errors.full_messages }, status: :unprocessable_content }
        end
      end
    end

    def update
      @thought = Thought.urlsafe_find!(params[:id])
      authorize! @thought
      @thought.assign_attributes(thought_params)

      update_with_event(record: @thought)

      if @thought.changed? # == thought still dirty, not saved
        render :edit, status: :unprocessable_content
      else
        redirect_to current_team_thought_url(@thought), notice: "Thought was successfully updated."
      end
    end

    def destroy
      @thought = Thought.urlsafe_find!(params[:id])
      authorize! @thought

      destroy_with_event(record: @thought)

      redirect_to current_team_thoughts_url, notice: "Thought was successfully destroyed."
    end

    private

    def thought_params
      params.expect(thought: %i[text date])
    end
  end
end
