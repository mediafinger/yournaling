class AdminShowRecordEventComponent < ApplicationComponent
  slim_template <<~SLIM
    article id= dom_id(@record_event)
      p
        strong Event:
          = @record_event.name

        = @record_event.created_at.to_formatted_s(:db)

        - if @record_event.done_by_admin?
          strong done by Admin
      p
        strong Record:
        = @record_link
        i
          > (
          = @record_event.record_yid
          > )
      p
        strong User:
        - if @user.present?
          = @user_link
        i
          > (
          = @record_event.user_yid
          > )
      p
        strong Team:
        - if @record_event.team_yid == "admin"
          > admin
        - elsif @record_event.team_yid == "none"
          > none
        - else
          - if @team.present?
            = @team_link
          i
            > (
            = @record_event.team_yid
            > )
      p
        strong YID:
        = @record_event.id
  SLIM

  def initialize(record_event:)
    @record_event = record_event

    @record = ApplicationRecordYidEnabled.fynd(record_event.record_yid)
    @user = User.find_by(yid: record_event.user_yid)
    @team = Team.find_by(yid: record_event.team_yid)
  end

  def before_render
    @record_link =
      if @record.present?
        link_to(@record.class.name, send(:"admin_#{@record.class.name.tableize.singularize}_path", @record))
      else
        ApplicationRecordYidEnabled.yid_code_models[@record_event.record_yid.split("_").first].name
      end

    @user_link = link_to(@user.name, admin_user_path(@user)) if @user
    @team_link = link_to(@team.name, admin_team_path(@team)) if @team
  end
end
