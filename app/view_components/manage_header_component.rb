# frozen_string_literal: true

# The header row of a record card in the manage area: the record name on the
# left (always an <h4>), and the action buttons grouped on the right —
# Open, Rewrite, and the visibility control.
#
# The visibility control replaces the old "Visibility: <state>" meta text plus
# pencil icon: when the current user may change visibility it is the primary
# button that opens ContentVisibilityModalComponent; otherwise it is a static
# badge showing the state. The record's date and creator live in the card
# footer now (see RecordFooterComponent), not here.
class ManageHeaderComponent < ApplicationComponent
  VISIBILITY_BADGE_VARIANTS = {
    "draft" => :neutral,
    "internal" => :info,
    "published" => :success,
    "archived" => :warning,
    "blocked" => :danger,
  }.freeze

  def initialize(record:, user: nil, team: nil, member: nil, title: nil,
                 hide_actions: false, full: false, heading_tag: nil)
    @record = record
    @user = user
    @team = team
    @member = member
    @title = title
    @hide_actions = hide_actions
    @full = full
    @heading_tag = heading_tag
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

  def title
    return @title if @title.present?

    case @record
    when Member then @record.user.name
    when Memory then @record.memo.to_s.truncate(60)
    when Thought then @record.text.to_s.truncate(60)
    else
      @record.try(:name).presence || @record.class.model_name.human
    end
  end

  def heading_tag
    @heading_tag || :h4
  end

  def show_path
    if @record.is_a?(Member)
      helpers.current_team_member_path(@record)
    else
      helpers.polymorphic_path([:current_team, @record])
    end
  end

  def edit_path
    if @record.is_a?(Member)
      helpers.edit_current_team_member_path(@record)
    else
      helpers.edit_polymorphic_path([:current_team, @record])
    end
  end

  def can_rewrite?
    return false if @hide_actions
    return false unless current_user.present?
    return false unless current_team == @record.team

    allowed_to?(:update?, @record)
  end

  def show_open_button?
    return false if @hide_actions
    return false if @full
    return false if helpers.respond_to?(:action_name) && helpers.action_name == "show"

    true
  end

  def show_visibility?
    !@hide_actions && @record.respond_to?(:visibility) && @record.visibility.present?
  end

  def can_change_visibility?
    return false unless show_visibility?
    return false unless current_user.present?

    allowed_to?(:update?, @record, with: ContentVisibilityPolicy)
  end

  def visibility_badge_variant
    VISIBILITY_BADGE_VARIANTS.fetch(@record.visibility.to_s, :neutral)
  end

  def visibility_label
    @record.visibility.to_s.capitalize
  end
end
