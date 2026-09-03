# frozen_string_literal: true

module Admins
  class StoriesController < AdminController
    def index
      @pagy, @stories = pagy(:offset, Story.includes(:team).order(created_at: :desc))
    end

    def show
      @story = Story.urlsafe_find!(params[:id])
    end

    def new
      @story = Story.new(team: current_team)
    end

    def edit
      @story = Story.urlsafe_find!(params[:id])
    end

    def create
      @story = Story.new(story_params)

      Story.create_with_event(record: @story, event_params: { team: nil, user: current_user, done_by_admin: true })

      if @story.persisted?
        redirect_to admin_story_url(@story), notice: "Story was successfully created."
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      @story = Story.urlsafe_find!(params[:id])
      @story.assign_attributes(story_params)

      Story.update_with_event(record: @story, event_params: { team: nil, user: current_user, done_by_admin: true })

      if @story.changed? # == story still dirty, not saved
        render :edit, status: :unprocessable_content
      else
        redirect_to admin_story_url(@story), notice: "Story was successfully updated."
      end
    end

    def destroy
      @story = Story.urlsafe_find!(params[:id])

      Story.destroy_with_event(record: @story, event_params: { team: nil, user: current_user, done_by_admin: true })

      redirect_to admin_stories_url, notice: "Story was successfully destroyed."
    end

    private

    def story_params
      params.expect(story: %i[name content date team_id])
    end
  end
end
