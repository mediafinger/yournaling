# frozen_string_literal: true

class AdminShowRecordEventComponent < ApplicationComponent
  def initialize(record_event:)
    @record_event = record_event
    @record = ApplicationRecordYidEnabled.fynd(record_event.record_id)
    @user = User.find_by(id: record_event.user_id)
    @team = Team.find_by(id: record_event.team_id)
  end

  attr_reader :record_event

  def occurred_at
    record_event.created_at.to_fs(:db)
  end

  def record_link
    if @record.present?
      link_to(@record.class.name, send(:"admin_#{@record.class.name.tableize.singularize}_path", @record),
        class: "ex-link")
    else
      ApplicationRecordYidEnabled.id_code_models[record_event.record_id.split("_").first].name
    end
  end

  def user_link
    return if @user.blank?

    link_to(@user.name, admin_user_path(@user), class: "ex-link")
  end

  def team_display
    case record_event.team_id
    when "admin" then "admin"
    when "none" then "none"
    else
      @team && link_to(@team.name, admin_team_path(@team), class: "ex-link")
    end
  end
end
