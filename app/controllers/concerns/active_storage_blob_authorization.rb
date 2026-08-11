# frozen_string_literal: true

module ActiveStorageBlobAuthorization
  extend ActiveSupport::Concern

  private

  def authorize_blob_access!
    return if @blob.blank?

    # Find records attached to this blob
    records = @blob.attachments.includes(:record).filter_map(&:record)

    # Allow if any attached record is publicly published
    return if records.any? { |r| r.respond_to?(:visibility) && r.visibility == "published" }

    # System administrators have full access across all media
    return if current_user.admin?

    # Reject unauthenticated guests for non-public content
    if current_user.new_record? || current_user.role == "guest"
      head :forbidden
      return
    end

    # Check team membership and visibility rules
    authorized = records.any? { |record| user_authorized_for_record?(record) }

    if authorized
      # Enforce private caching for authenticated media to avoid shared CDN / cache leaks
      response.headers["Cache-Control"] = "private, no-transform"
    else
      head :forbidden
    end
  end

  def user_authorized_for_record?(record)
    if record.respond_to?(:team) && record.team.present?
      member = current_user.memberships.find_by(team: record.team)
      return false if member.blank?

      if record.visibility == "archived"
        member.roles.intersect?(%w[owner manager])
      else
        true
      end
    elsif record.respond_to?(:user)
      record.user == current_user
    else
      false
    end
  end
end
