# frozen_string_literal: true

module Publishable
  extend ActiveSupport::Concern

  included do
    has_one :publishing, as: :post, dependent: :destroy, foreign_type: :post_type

    after_save :sync_publishing
  end

  private

  def sync_publishing
    now = Time.current

    if visibility == "published"
      if publishing.nil?
        create_publishing!(
          team_id: team_id,
          first_published_at: now,
          republished_at: now,
          published_count: 1,
          visibility: "published"
        )
      else
        was_not_published = saved_change_to_visibility? && saved_changes["visibility"].first != "published"
        attributes = { visibility: "published", team_id: team_id }
        if was_not_published
          attributes[:republished_at] = now
          attributes[:published_count] = (publishing.published_count || 0) + 1
        end
        publishing.update!(attributes)
      end
    elsif publishing.present? && saved_change_to_visibility?
      publishing.update!(visibility: visibility, team_id: team_id)
    end
  end
end
