# frozen_string_literal: true

class ManageHeaderComponent < ApplicationComponent
  def initialize(record:, user: nil, team: nil, member: nil, title: nil, date: nil, date_label: nil,
                 hide_actions: false, full: false, heading_tag: nil)
    @record = record
    @user = user
    @team = team
    @member = member
    @title = title
    @date = date
    @date_label = date_label
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
    @member.presence || (respond_to?(:helpers) && helpers.respond_to?(:current_member) ? helpers.current_member : super)
  end

  def title
    return @title if @title.present?

    if @record.is_a?(Member)
      @record.user.name
    elsif @record.respond_to?(:name) && @record.name.present?
      @record.name
    else
      @record.class.model_name.human
    end
  end

  def date
    return @date if @date.present?

    if @record.is_a?(Chronicle)
      if @record.end_date.present?
        "#{@record.start_date} – #{@record.end_date}"
      else
        @record.start_date.to_s
      end
    elsif @record.respond_to?(:date) && @record.date.present?
      @record.date.to_s
    elsif @record.respond_to?(:created_at) && @record.created_at.present?
      @record.created_at.to_date.to_s
    end
  end

  def date_label
    return @date_label if @date_label.present?

    if @record.is_a?(Member)
      "Member since"
    elsif @record.is_a?(Chronicle) && @record.end_date.present?
      "Dates"
    else
      "Date"
    end
  end

  def heading_tag
    @heading_tag || (@record.is_a?(Chronicle) ? :h3 : :h4)
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
end
