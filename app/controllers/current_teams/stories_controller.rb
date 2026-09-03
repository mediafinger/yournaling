# frozen_string_literal: true

module CurrentTeams
  class StoriesController < AppCurrentTeamController
    skip_before_action :authenticate, only: %i[index show] # allow everyone to see the stories

    def index
      authorize! current_user, to: :index?, with: StoryPolicy

      @stories = Story.all
    end

    def show
      @story = Story.urlsafe_find!(params[:id])
      authorize! @story
    end

    def new
      @story = Story.new(team: current_team)
      authorize! @story
    end

    def edit
      @story = Story.urlsafe_find!(params[:id])
      authorize! @story
    end

    def create
      @story = Story.new(
        name: story_params[:name],
        content: story_params[:content],
        date: story_params[:date],
        team: current_team
      )

      authorize! @story

      create_with_event(record: @story)

      respond_to do |format|
        if @story.persisted?
          format.html { redirect_to current_team_story_url(@story), notice: "Story was successfully created." }
          format.json { render json: { id: @story.id, text: @story.name, type: "story" }, status: :created }
        else
          format.html { render :new, status: :unprocessable_content }
          format.json { render json: { errors: @story.errors.full_messages }, status: :unprocessable_content }
        end
      end
    end

    def update
      @story = Story.urlsafe_find!(params[:id])
      authorize! @story
      @story.assign_attributes(story_params)

      update_with_event(record: @story)

      if @story.changed? # == story still dirty, not saved
        render :edit, status: :unprocessable_content
      else
        redirect_to current_team_story_url(@story), notice: "Story was successfully updated."
      end
    end

    def destroy
      @story = Story.urlsafe_find!(params[:id])
      authorize! @story

      if @story.chronicle_entries.exists?
        redirect_to edit_current_team_story_url(@story),
          alert: "Story cannot be destroyed because it is still referenced by other content."
      else
        destroy_with_event(record: @story)
        redirect_to current_team_stories_url, notice: "Story was successfully destroyed."
      end
    end

    private

    def story_params
      params.expect(story: %i[name content date])
    end
  end
end
