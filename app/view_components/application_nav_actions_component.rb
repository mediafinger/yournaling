class ApplicationNavActionsComponent < ApplicationComponent
  erb_template <<-ERB
    <ul>
      <li>
        <%= @action_buttons %>
      </li>
    </ul>
  ERB

  def initialize(actions_for: [])
    @sections = actions_for
  end

  def before_render
    @active_section = @sections.find { |section| active_path?(send(:"#{section}_path")) }
    @action_buttons = render partial: "#{@active_section}/action_buttons" if @active_section && current_team
  end
end
