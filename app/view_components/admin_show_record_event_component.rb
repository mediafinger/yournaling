class AdminShowRecordEventComponent < ApplicationComponent
  erb_template <<-ERB
    <article id="<%=dom_id(@record_event)%>">
      <p>
        <strong>
          Event:
          <%= @record_event.name %>
        </strong>
        <%= @record_event.created_at.to_formatted_s(:db) %>
        <% if @record_event.done_by_admin? %>
          <strong>done by Admin</strong>
        <% end %>
      </p>

      <p>
        <strong>Record:</strong>
        <%= @record_link %>
        <i>(<%= @record_event.record_yid %>)</i>
      </p>

      <p>
        <strong>User:</strong>
        <% if @user.present? %>
          <%= @user_link %>
        <% end %>
        <i>(<%= @record_event.user_yid %>)</i>
      </p>

      <p>
        <strong>Team:</strong>
        <% if @record_event.team_yid == "admin" %>
          admin
        <% elsif @record_event.team_yid == "none" %>
          none
        <% else %>
          <% if @team.present? %>
            <%= @team_link %>
          <% end %>
          <i>(<%= @record_event.team_yid %>)</i>
        <% end %>
      </p>

      <p>
        <strong>YID:</strong>
        <%= @record_event.id %>
      </p>
    </article>
  ERB

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
