# frozen_string_literal: true

class MemoryInsightAttacher
  class << self
    def call(memory:, params:, user: nil)
      new(memory:, user:).attach(params)
    end
  end

  def initialize(memory:, user: nil)
    @memory = memory
    @team = memory.team
    @user = user
    @resolver = InsightResolver.new(
      parent: memory,
      team: team,
      date: memory.created_at&.to_date,
      visibility: memory.visibility,
      user: user
    )
  end

  def attach(params)
    return if params.blank?

    validate_mutual_exclusivity!(params)

    ActiveRecord::Base.transaction do
      attach_picture(params)
      attach_location(params)
      attach_thought(params)
      attach_weblink(params)

      memory.save! if memory.changed?
    end
  end

  private

  attr_reader :memory, :team, :user, :resolver

  def validate_mutual_exclusivity!(params)
    if params[:picture_id].present? && params[:picture_file].respond_to?(:tempfile)
      memory.errors.add(:picture_id, "Please either select an existing picture or upload a new picture, not both")
    end

    if params[:location_id].present? && (
      params[:location_name].present? || params[:location_address].present? ||
      params[:location_url].present? || params[:location_country_code].present?
    )
      memory.errors.add(:location_id, "Please either select an existing location or create a new location, not both")
    end

    if params[:thought_id].present? && params[:thought_text].present?
      memory.errors.add(:thought_id, "Please either select an existing thought or create a new thought, not both")
    end

    if params[:weblink_id].present? && (params[:weblink_url].present? || params[:weblink_name].present?)
      memory.errors.add(:weblink_id, "Please either select an existing weblink or create a new weblink, not both")
    end

    raise ActiveRecord::RecordInvalid.new(memory) if memory.errors.any?
  end

  def attach_picture(params)
    return unless params.key?(:picture_id) || params.key?(:picture_file) || params.key?(:picture_name)

    if (uploaded_pic = resolver.resolve_picture_upload(
      picture_file: params[:picture_file],
      picture_name: params[:picture_name]
    ))
      memory.picture = uploaded_pic
    elsif params[:picture_id].present?
      memory.picture = resolver.find_existing_picture(params[:picture_id])
    elsif params.key?(:picture_id) && params[:picture_id].blank?
      memory.picture = nil
    end
  end

  def attach_location(params)
    return unless params.key?(:location_id) || params.key?(:location_name) ||
                  params.key?(:location_address) || params.key?(:location_url)

    target_loc = resolver.resolve_location(
      location_id: params[:location_id],
      location_name: params[:location_name],
      location_address: params[:location_address],
      location_country_code: params[:location_country_code],
      location_url: params[:location_url],
      location_description: params[:location_description]
    )
    memory.location = target_loc
  end

  def attach_thought(params)
    return unless params.key?(:thought_id) || params.key?(:thought_text)

    target_thought = resolver.resolve_thought(
      thought_id: params[:thought_id],
      thought_text: params[:thought_text]
    )
    memory.thought = target_thought
  end

  def attach_weblink(params)
    return unless params.key?(:weblink_id) || params.key?(:weblink_name) || params.key?(:weblink_url)

    target_weblink = resolver.resolve_weblink(
      weblink_id: params[:weblink_id],
      weblink_name: params[:weblink_name],
      weblink_url: params[:weblink_url],
      weblink_description: params[:weblink_description]
    )
    memory.weblink = target_weblink
  end
end
