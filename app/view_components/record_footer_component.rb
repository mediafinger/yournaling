# frozen_string_literal: true

# The footer row of a record card: the record's date on the left, and on the
# right either the owning team (browse) or the user who created the record
# (manage). Rendered inside `Yui::CardComponent`'s footer slot.
#
#   = render RecordFooterComponent.new(record: chronicle, scope: :browse, team: team)
#   = render RecordFooterComponent.new(record: story, scope: :manage)
#
# scope:  :browse → "@TeamName" linked to the team's public timeline
#         :manage → the creator's user name, or "Unknown" when no `created`
#                   RecordEvent exists (see RecordEvent.creator_for — N+1).
class RecordFooterComponent < ApplicationComponent
  UNKNOWN_CREATOR = "Unknown"

  attr_reader :record, :scope, :team

  def initialize(record:, scope: :manage, team: nil, date: nil)
    super()
    @record = record
    @scope = scope.to_sym
    @team = team || record.try(:team)
    @date = date
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
end
