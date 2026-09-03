# frozen_string_literal: true

class ContentVisibilityModalComponent < ApplicationComponent
  def initialize(record:, user: nil, team: nil, member: nil)
    @record = record
    @user = user
    @team = team
    @member = member
  end

  def render?
    return false if @record.blank?
    return false unless current_user.present?

    allowed_to?(:update?, @record, with: ContentVisibilityPolicy)
  end

  def current_user
    @user.presence || (respond_to?(:helpers) && helpers.respond_to?(:current_user) ? helpers.current_user : super)
  end

  def current_team
    @team.presence || (respond_to?(:helpers) && helpers.respond_to?(:current_team) ? helpers.current_team : super)
  end

  def current_member
    return @member if @member.present?
    # No persisted user (guest browsing, or a Lookbook preview) => no membership
    # to look up. Guard the DB fallback so `current_member` never raises here.
    return nil unless current_user&.persisted?

    respond_to?(:helpers) && helpers.respond_to?(:current_member) ? helpers.current_member : super
  end

  def visibility_states
    @record.class::VISIBILITY_STATES - %w[blocked]
  end
end
