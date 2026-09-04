# frozen_string_literal: true

class BrowseHeaderComponent < ApplicationComponent
  def initialize(record:, team: nil, user: nil, member: nil, title: nil, date: nil, full: false)
    super()
    @record = record
    @team = team || record.try(:team)
    @user = user
    @member = member
    @title = title
    @date = date
    @full = full
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

  # See ManageHeaderComponent#title — Memory's memo is shown in full in the
  # card body right below, so a truncated repeat of it as the header title
  # would be redundant.
  def title
    return @title if @title.present?

    case @record
    when Member then @record.user.name
    when Memory then nil
    when Thought then @record.text.to_s.truncate(60)
    else
      @record.try(:name).presence || @record.class.model_name.human
    end
  end

  def show_path
    case @record
    when Chronicle
      helpers.team_chronicle_path(@team, @record)
    when Memory
      helpers.team_memory_path(@team, @record)
    when Picture
      helpers.team_picture_path(@team, @record)
    end
  end

  def edit_path
    helpers.edit_polymorphic_path([:current_team, @record])
  end

  def can_rewrite?
    return false unless current_user.present?
    return false unless current_team.present? && current_team == @record.try(:team)

    allowed_to?(:update?, @record)
  end

  def show_open_button?
    return false if @full
    return false if helpers.respond_to?(:controller_name) &&
                    helpers.controller_name == @record.class.model_name.plural &&
                    helpers.action_name == "show"
    return false if show_path.blank?

    true
  end
end
