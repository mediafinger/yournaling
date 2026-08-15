# frozen_string_literal: true

module ChronicleAttachableInsights
  extend ActiveSupport::Concern

  include AttachablePicture
  include AttachableLocation
  include AttachableThought
  include AttachableWeblink

  INSIGHT_PARAM_KEYS = %i[
    picture_id picture_file picture_name
    location_id location_name location_address location_country_code location_url location_description
    thought_id thought_text
    weblink_id weblink_name weblink_url weblink_description
  ].freeze

  class_methods do
    def extract_insight_params!(attrs)
      INSIGHT_PARAM_KEYS.each_with_object({}) do |key, extracted|
        extracted[key] = attrs.delete(key) if attrs.key?(key)
      end
    end
  end

  def attach_insights(params, user: nil)
    return if params.blank?

    attach_picture(
      picture_id: params[:picture_id],
      picture_file: params[:picture_file],
      picture_name: params[:picture_name],
      user: user
    )
    attach_location(
      location_id: params[:location_id],
      location_name: params[:location_name],
      location_address: params[:location_address],
      location_country_code: params[:location_country_code],
      location_url: params[:location_url],
      location_description: params[:location_description],
      user: user
    )
    attach_thought(
      thought_id: params[:thought_id],
      thought_text: params[:thought_text],
      user: user
    )
    attach_weblink(
      weblink_id: params[:weblink_id],
      weblink_name: params[:weblink_name],
      weblink_url: params[:weblink_url],
      weblink_description: params[:weblink_description],
      user: user
    )
  end
end
