class AdminShowRecordHistoryComponent < ApplicationComponent
  slim_template <<~SLIM
    article id= dom_id(@record_history)
      p
        strong Event:
          = @record_history.event

        = @record_history.created_at.to_formatted_s(:db)

        - if @record_history.done_by_admin?
          strong done by Admin
      p
        strong Record:
        = @record_link
        i
          > (
          = @record_history.record_yid
          > )
      p
        strong User:
        - if @user.present?
          = @user_link
        i
          > (
          = @record_history.user_yid
          > )
      p
        strong Team:
        - if @record_history.team_yid == "admin"
          > admin
        - elsif @record_history.team_yid == "none"
          > none
        - else
          - if @team.present?
            = @team_link
          i
            > (
            = @record_history.team_yid
            > )
      p
        strong YID:
        = @record_history.id
  SLIM

  def initialize(record_history:)
    @record_history = record_history

    @record = ApplicationRecordYidEnabled.fynd(record_history.record_yid)
    @user = User.find_by(yid: record_history.user_yid)
    @team = Team.find_by(yid: record_history.team_yid)
  end

  def before_render
    @record_link =
      if @record.present?
        link_to(@record.class.name, send(:"admin_#{@record.class.name.tableize.singularize}_path", @record))
      else
        ApplicationRecordYidEnabled.yid_code_models[@record_history.record_yid.split("_").first].name
      end

    @user_link = link_to(@user.name, admin_user_path(@user)) if @user
    @team_link = link_to(@team.name, admin_team_path(@team)) if @team
  end
end
