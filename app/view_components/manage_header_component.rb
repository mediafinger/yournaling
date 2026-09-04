# frozen_string_literal: true

# The header row of a record card in the manage area.
#
# actions_in_header: true (default) — the original layout: the record name on
#   the left as plain text, Open / Rewrite / the visibility control grouped on
#   the right. Still used by Member, which this redesign leaves untouched.
# actions_in_header: false — used by Chronicle and the manage insight cards
#   (Story, Thought, Location, Weblink, Picture): just the record name,
#   rendered as a plain-looking link to its show page (underlines only on
#   hover — see .yui-link--cover). Rewrite and the visibility control live in
#   the card footer instead — see RecordFooterComponent.
class ManageHeaderComponent < ApplicationComponent
  include VisibilityControl

  def initialize(record:, user: nil, team: nil, member: nil, title: nil,
                 hide_actions: false, full: false, heading_tag: nil, actions_in_header: true)
    @record = record
    @user = user
    @team = team
    @member = member
    @title = title
    @hide_actions = hide_actions
    @full = full
    @heading_tag = heading_tag
    @actions_in_header = actions_in_header
  end

  def actions_in_header?
    @actions_in_header
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

  # Whether there's somewhere useful to send the viewer for this record —
  # renders as the "Open" button when actions_in_header?, or makes the title
  # a link otherwise. False when we're already on the record's own show page —
  # checking action_name alone isn't enough: the manage home feed is also
  # rendered by an action literally named "show" (PagesController#show), which
  # isn't this record's own page at all.
  def show_open_button?
    return false if @hide_actions
    return false if @full
    return false if controller_name == @record.class.model_name.plural && action_name == "show"

    true
  end

  private

  def controller_name
    helpers.controller.controller_name
  end

  def action_name
    helpers.controller.action_name
  end
end
