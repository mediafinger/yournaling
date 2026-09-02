# frozen_string_literal: true

class InsightResolver
  def initialize(parent:, team:, date:, visibility:, user: nil)
    @parent = parent
    @team = team
    @date = date
    @visibility = visibility
    @user = user
  end

  def resolve_picture_upload(picture_file:, picture_name: nil)
    return nil unless picture_file.respond_to?(:tempfile)

    p_name = picture_name.presence || File.basename(picture_file.original_filename, ".*").titleize
    pic = Picture.new(
      file: ImageUploadConversionService.call(file: picture_file, name: p_name),
      name: p_name,
      date: date,
      team: team,
      visibility: visibility
    )
    Picture.create_with_event(record: pic, event_params: { team: team, user: user })
    if pic.persisted?
      pic
    else
      merge_errors_and_raise!(pic, :picture_file)
    end
  end

  def find_existing_picture(picture_id)
    return nil if picture_id.blank?

    team.pictures.find_by(id: picture_id) || team.pictures.urlsafe_find(picture_id)
  end

  def resolve_location(location_id: nil, location_name: nil, location_address: nil, location_country_code: nil,
                       location_url: nil, location_description: nil)
    if location_name.present? || location_address.present?
      loc = Location.new(
        name: location_name.presence || location_address,
        address: location_address,
        country_code: location_country_code.presence,
        url: location_url,
        description: location_description,
        date: date,
        team: team,
        visibility: visibility
      )
      Location.create_with_event(record: loc, event_params: { team: team, user: user })
      if loc.persisted?
        loc
      else
        merge_errors_and_raise!(loc, :location_name)
      end
    elsif location_id.present?
      team.locations.find_by(id: location_id) || team.locations.urlsafe_find(location_id)
    end
  end

  def resolve_story(story_id: nil, story_name: nil, story_content: nil)
    if story_content.present? || story_name.present?
      story = Story.new(
        name: story_name.presence || "Untitled story",
        content: story_content,
        date: date,
        team: team,
        visibility: visibility
      )
      Story.create_with_event(record: story, event_params: { team: team, user: user })
      if story.persisted?
        story
      else
        merge_errors_and_raise!(story, :story_content)
      end
    elsif story_id.present?
      team.stories.find_by(id: story_id) || team.stories.urlsafe_find(story_id)
    end
  end

  def resolve_thought(thought_id: nil, thought_text: nil)
    if thought_text.present?
      thot = Thought.new(
        text: thought_text,
        date: date,
        team: team,
        visibility: visibility
      )
      Thought.create_with_event(record: thot, event_params: { team: team, user: user })
      if thot.persisted?
        thot
      else
        merge_errors_and_raise!(thot, :thought_text)
      end
    elsif thought_id.present?
      team.thoughts.find_by(id: thought_id) || team.thoughts.urlsafe_find(thought_id)
    end
  end

  def resolve_weblink(weblink_id: nil, weblink_name: nil, weblink_url: nil, weblink_description: nil)
    if weblink_url.present? || weblink_name.present?
      link = Weblink.new(
        name: weblink_name.presence || weblink_url,
        url: weblink_url,
        description: weblink_description,
        date: date,
        team: team,
        visibility: visibility
      )
      Weblink.create_with_event(record: link, event_params: { team: team, user: user })
      if link.persisted?
        link
      else
        merge_errors_and_raise!(link, :weblink_url)
      end
    elsif weblink_id.present?
      team.weblinks.find_by(id: weblink_id) || team.weblinks.urlsafe_find(weblink_id)
    end
  end

  def merge_errors_and_raise!(record, fallback_attribute)
    prefix_name = fallback_attribute.to_s.split("_").first
    record.errors.each do |error|
      attr_key = if error.attribute == :base
                   fallback_attribute
                 else
                   :"#{prefix_name}_#{error.attribute}"
                 end
      parent.errors.add(attr_key, error.message)
    end
    raise ActiveRecord::RecordInvalid.new(parent)
  end

  private

  attr_reader :parent, :team, :date, :visibility, :user
end
