# frozen_string_literal: true

# The footer row of a record card, up to three zones:
#
#   date  ·  [center: visibility control (manage) | custom slot]  ·  Rewrite + owner
#
# - date: bottom-left.
# - center: in :manage scope, the visibility control (see VisibilityControl) —
#   the primary button that opens ContentVisibilityModalComponent when the
#   viewer may change it, a static badge otherwise. Callers needing a
#   different center (e.g. ChronicleCardComponent's browse-mode "Show more")
#   pass their own via `with_center` — it takes priority.
# - right: the Rewrite button (when the viewer may edit the record), directly
#   left of the owner — "@TeamName" linked to the team's public timeline in
#   :browse, or the creator's name / "Unknown" in :manage (read from the
#   record's `created` RecordEvent — see RecordEvent.creator_for, N+1).
#
#   = render RecordFooterComponent.new(record: chronicle, scope: :browse, team: team)
#   = render RecordFooterComponent.new(record: story, scope: :manage)
#
# show_rewrite / show_visibility: false suppresses that zone even where it
# would otherwise apply — used for a record embedded read-only inside another
# card's content (hide_actions on the outer card).
class RecordFooterComponent < ApplicationComponent
  include VisibilityControl

  renders_one :center

  UNKNOWN_CREATOR = "Unknown"

  attr_reader :record, :scope, :team, :member

  def initialize(record:, scope: :manage, team: nil, user: nil, member: nil, date: nil,
                 show_rewrite: true, show_visibility: true)
    super()
    @record = record
    @scope = scope.to_sym
    @team = team || record.try(:team)
    @user = user
    @member = member
    @date = date
    @show_rewrite = show_rewrite
    @show_visibility = show_visibility
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

  def date
    return @date if @date.present?

    if record.is_a?(Chronicle)
      record.end_date.present? ? "#{record.start_date} – #{record.end_date}" : record.start_date.to_s
    elsif record.respond_to?(:date) && record.date.present?
      record.date.to_s
    elsif record.respond_to?(:created_at) && record.created_at.present?
      record.created_at.to_date.to_s
    end
  end

  def browse?
    scope == :browse
  end

  def manage?
    scope == :manage
  end

  def show_visibility_control?
    @show_visibility && manage? && show_visibility?
  end

  def team_handle
    "@#{team.name}"
  end

  # A persisted team has a route; the in-memory records on /example and in
  # Lookbook previews do not, so there the handle renders as plain text.
  def team_timeline_path
    helpers.team_home_path(team) if team&.persisted?
  end

  def creator_name
    RecordEvent.creator_for(record)&.name.presence || UNKNOWN_CREATOR
  end

  def can_rewrite?
    return false unless @show_rewrite
    return false unless current_user.present?
    return false unless current_team.present? && current_team == record.try(:team)

    allowed_to?(:update?, record)
  end

  def edit_path
    if record.is_a?(Member)
      helpers.edit_current_team_member_path(record)
    else
      helpers.edit_polymorphic_path([:current_team, record])
    end
  end
end
