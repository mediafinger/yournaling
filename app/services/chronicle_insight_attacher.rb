# frozen_string_literal: true

class ChronicleInsightAttacher
  INSIGHT_PARAM_KEYS = %i[
    entry_ids
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
    @resolver = InsightResolver.new(
      parent: chronicle,
      team: team,
      date: chronicle.start_date,
      visibility: chronicle.visibility,
      user: user
    )
  end

  def attach(params)
    return if params.blank?

    ActiveRecord::Base.transaction do
      attach_entry_ids(params[:entry_ids])
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

  attr_reader :chronicle, :team, :user, :resolver

  def attach_entry_ids(entry_ids)
    Array(entry_ids).compact_blank.each do |id|
      entry_record = find_entry_by_id(id)
      next unless entry_record

      chronicle.entries.create!(entry: entry_record, team: team)
    end
  end

  def find_entry_by_id(id)
    team.pictures.find_by(id: id) ||
      team.locations.find_by(id: id) ||
      team.thoughts.find_by(id: id) ||
      team.weblinks.find_by(id: id) ||
      team.memories.find_by(id: id)
  end

  def attach_picture(picture_id: nil, picture_file: nil, picture_name: nil)
    if (uploaded_pic = resolver.resolve_picture_upload(picture_file: picture_file, picture_name: picture_name))
      chronicle.entries.create!(entry: uploaded_pic, team: team)
    end

    return unless picture_id.present?

    if (existing_pic = resolver.find_existing_picture(picture_id))
      chronicle.entries.create!(entry: existing_pic, team: team)
    end
  end

  def attach_location(location_id: nil, location_name: nil, location_address: nil, location_country_code: nil,
                      location_url: nil, location_description: nil)
    target_loc = resolver.resolve_location(
      location_id: location_id,
      location_name: location_name,
      location_address: location_address,
      location_country_code: location_country_code,
      location_url: location_url,
      location_description: location_description
    )
    chronicle.entries.create!(entry: target_loc, team: team) if target_loc
  end

  def attach_thought(thought_id: nil, thought_text: nil)
    target_thought = resolver.resolve_thought(
      thought_id: thought_id,
      thought_text: thought_text
    )
    chronicle.entries.create!(entry: target_thought, team: team) if target_thought
  end

  def attach_weblink(weblink_id: nil, weblink_name: nil, weblink_url: nil, weblink_description: nil)
    target_weblink = resolver.resolve_weblink(
      weblink_id: weblink_id,
      weblink_name: weblink_name,
      weblink_url: weblink_url,
      weblink_description: weblink_description
    )
    chronicle.entries.create!(entry: target_weblink, team: team) if target_weblink
  end
end
