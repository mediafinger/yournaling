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
          = @record_event.record_id
          > )
      p
        strong User:
        - if @user.present?
          = @user_link
        i
          > (
          = @record_event.user_id
          > )
      p
        strong Team:
        - if @record_event.team_id == "admin"
          > admin
        - elsif @record_event.team_id == "none"
          > none
        - else
          - if @team.present?
            = @team_link
          i
            > (
            = @record_event.team_id
            > )
      p
        strong ID:
        = @record_event.id
  SLIM

  def initialize(record_event:)
    @record_event = record_event

    @record = ApplicationRecordYidEnabled.fynd(record_event.record_id)
    @user = User.find_by(id: record_event.user_id)
    @team = Team.find_by(id: record_event.team_id)
  end

  def before_render
    @record_link =
      if @record.present?
        link_to(@record.class.name, send(:"admin_#{@record.class.name.tableize.singularize}_path", @record))
      else
        ApplicationRecordYidEnabled.id_code_models[@record_event.record_id.split("_").first].name
      end

    @user_link = link_to(@user.name, admin_user_path(@user)) if @user
    @team_link = link_to(@team.name, admin_team_path(@team)) if @team
  end
end
