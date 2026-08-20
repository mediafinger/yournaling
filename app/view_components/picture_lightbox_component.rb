# frozen_string_literal: true

class PictureLightboxComponent < ApplicationComponent
  attr_reader :picture, :team, :size

  def initialize(picture:, team: nil, size: :preview)
    super()
    @picture = picture
    @team = team || picture&.team
    @size = size
  end

  def render?
    picture&.persisted? && picture.file.attached?
  end

  def original_picture_url
    if picture.visibility == "published" && team.present?
      team_picture_only_path(team_id: team.to_param, id: picture.to_param)
    elsif picture.file.attached?
      rails_blob_path(picture.file)
    end
  end

  def picture_title
    picture.name.presence || "Picture"
  end
end
