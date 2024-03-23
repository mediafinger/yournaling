class ApplicationNavActionsComponent < ApplicationComponent
  erb_template <<-ERB
    <ul>
      <li>
        <%= @action_buttons %>
      </li>
    </ul>
  ERB

  def initialize(actions_for: [], scope: nil)
    @sections = actions_for
    @scope = scope
  end

  def before_render
    @active_section = @sections.find do |section|
      path_prefix = [@scope, section].compact.join("_")
      active_path?(send(:"#{path_prefix}_path"))
    end

    return unless @active_section && (current_team || @scope == "admin")
    return if @active_section == "record_history"

    @action_buttons = render partial: "#{@active_section}/action_buttons"
  end
end
