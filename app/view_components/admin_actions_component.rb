class AdminActionsComponent < ApplicationComponent
  erb_template <<-ERB
    <% if action_name != "show" %>
      <%= @show_link %>
    <% end %>
    <%= @edit_link %>
    <%= @events_link %>
  ERB

  def initialize(record:, name:)
    @record = record
    @name = name
  end

  def before_render
    show_path = send(:"admin_#{@name}_path", @record)
    edit_path = send(:"edit_admin_#{@name}_path", @record)

    @show_link = link_to "Show this #{@name}", show_path, role: "button"
    @edit_link = link_to "Edit this #{@name}", edit_path, role: "button", class: "secondary"
    @events_link =
      link_to "Events", admin_record_events_path(record_yid: @record.to_param), role: "button", class: "secondary"
  end
end
