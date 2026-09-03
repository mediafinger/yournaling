# frozen_string_literal: true

class InsightAttachmentManagerComponent < ApplicationComponent
  def initialize(form:, scope: "current_team", mode: "single")
    @form = form
    @record = form.object
    @scope = scope
    @mode = mode.to_s
  end

  def record_name
    @record.model_name.param_key
  end

  def allowed_image_types_accept
    Picture::ALLOWED_IMAGE_TYPES.map { |type| ".#{type}" }.join(", ")
  end

  def team
    @record.team || (helpers.current_team if helpers.respond_to?(:current_team))
  end

  def team_locations
    if team
      team.locations.order(name: :asc)
    elsif @scope == "admin"
      Location.order(name: :asc)
    else
      Location.none
    end
  end

  def team_pictures
    if team
      team.pictures.order(created_at: :desc)
    elsif @scope == "admin"
      Picture.order(created_at: :desc)
    else
      Picture.none
    end
  end

  def team_stories
    if team
      team.stories.order(created_at: :desc)
    elsif @scope == "admin"
      Story.order(created_at: :desc)
    else
      Story.none
    end
  end

  def team_thoughts
    if team
      team.thoughts.order(created_at: :desc)
    elsif @scope == "admin"
      Thought.order(created_at: :desc)
    else
      Thought.none
    end
  end

  def team_weblinks
    if team
      team.weblinks.order(name: :asc)
    elsif @scope == "admin"
      Weblink.order(name: :asc)
    else
      Weblink.none
    end
  end

  def create_location_url
    @scope == "admin" ? "/admin/locations.json" : "/current_team/locations.json"
  end

  def create_picture_url
    @scope == "admin" ? "/admin/pictures.json" : "/current_team/pictures.json"
  end

  def create_story_url
    @scope == "admin" ? "/admin/stories.json" : "/current_team/stories.json"
  end

  def create_thought_url
    @scope == "admin" ? "/admin/thoughts.json" : "/current_team/thoughts.json"
  end

  def create_weblink_url
    @scope == "admin" ? "/admin/weblinks.json" : "/current_team/weblinks.json"
  end
end
