# frozen_string_literal: true

class ChronicleInsightAttacher
  INSIGHT_PARAM_KEYS = %i[
    picture_id picture_file picture_name
    location_id location_name location_address location_country_code location_url location_description
    thought_id thought_text
    weblink_id weblink_name weblink_url weblink_description
  ].freeze

  class << self
    def extract_insight_params!(attrs)
      INSIGHT_PARAM_KEYS.each_with_object({}) do |key, extracted|
        extracted[key] = attrs.delete(key) if attrs.key?(key)
      end
    end

    def call(chronicle:, params:, user: nil)
      new(chronicle:, user:).attach(params)
    end
  end

  def initialize(chronicle:, user: nil) # TODO: why user: nil - when do we not need a user? And when do we not have a user?
    @chronicle = chronicle
    @team = chronicle.team
    @user = user
  end

  def attach(params)
    return if params.blank?

    ActiveRecord::Base.transaction do
      attach_picture(
        picture_id: params[:picture_id],
        picture_file: params[:picture_file],
        picture_name: params[:picture_name]
      )
      attach_location(
        location_id: params[:location_id],
        location_name: params[:location_name],
        location_address: params[:location_address],
        location_country_code: params[:location_country_code],
        location_url: params[:location_url],
        location_description: params[:location_description]
      )
      attach_thought(
        thought_id: params[:thought_id],
        thought_text: params[:thought_text]
      )
      attach_weblink(
        weblink_id: params[:weblink_id],
        weblink_name: params[:weblink_name],
        weblink_url: params[:weblink_url],
        weblink_description: params[:weblink_description]
      )
    end
  end

  private

  attr_reader :chronicle, :team, :user

  def attach_picture(picture_id: nil, picture_file: nil, picture_name: nil)
    target_picture = if picture_file.respond_to?(:tempfile)
                       p_name = picture_name.presence || File.basename(picture_file.original_filename, ".*").titleize
                       pic = Picture.new(
                         file: ImageUploadConversionService.call(file: picture_file, name: p_name),
                         name: p_name,
                         date: chronicle.start_date,
                         team: team,
                         visibility: chronicle.visibility
                       )
                       Picture.create_with_event(record: pic, event_params: { team: team, user: user })
                       pic if pic.persisted?
                     elsif picture_id.present?
                       team.pictures.find_by(id: picture_id) || team.pictures.urlsafe_find(picture_id)
                     end

    return unless target_picture

    chronicle.entries.create!(entry: target_picture, team: team)
  end

  def attach_location(location_id: nil, location_name: nil, location_address: nil, location_country_code: nil,
                      location_url: nil, location_description: nil)
    target_location = if location_name.present? || location_address.present?
                        loc = Location.new(
                          name: location_name.presence || location_address,
                          address: location_address,
                          country_code: location_country_code.presence,
                          url: location_url,
                          description: location_description,
                          date: chronicle.start_date,
                          team: team,
                          visibility: chronicle.visibility
                        )
                        Location.create_with_event(record: loc, event_params: { team: team, user: user })
                        loc if loc.persisted?
                      elsif location_id.present?
                        team.locations.find_by(id: location_id) || team.locations.urlsafe_find(location_id)
                      end

    return unless target_location

    chronicle.entries.create!(entry: target_location, team: team)
  end

  def attach_thought(thought_id: nil, thought_text: nil)
    target_thought = if thought_text.present?
                       thot = Thought.new(
                         text: thought_text,
                         date: chronicle.start_date,
                         team: team,
                         visibility: chronicle.visibility
                       )
                       Thought.create_with_event(record: thot, event_params: { team: team, user: user })
                       thot if thot.persisted?
                     elsif thought_id.present?
                       team.thoughts.find_by(id: thought_id) || team.thoughts.urlsafe_find(thought_id)
                     end

    return unless target_thought

    chronicle.entries.create!(entry: target_thought, team: team)
  end

  def attach_weblink(weblink_id: nil, weblink_name: nil, weblink_url: nil, weblink_description: nil)
    target_weblink = if weblink_url.present? || weblink_name.present?
                       link = Weblink.new(
                         name: weblink_name.presence || weblink_url,
                         url: weblink_url,
                         description: weblink_description,
                         date: chronicle.start_date,
                         team: team,
                         visibility: chronicle.visibility
                       )
                       Weblink.create_with_event(record: link, event_params: { team: team, user: user })
                       link if link.persisted?
                     elsif weblink_id.present?
                       team.weblinks.find_by(id: weblink_id) || team.weblinks.urlsafe_find(weblink_id)
                     end

    return unless target_weblink

    chronicle.entries.create!(entry: target_weblink, team: team)
  end
end
