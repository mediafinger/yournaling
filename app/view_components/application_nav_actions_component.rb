class ApplicationNavActionsComponent < ApplicationComponent
  slim_template <<~SLIM
    ul
      li
        = @action_buttons
  SLIM

  def initialize(actions_for: [], scope: nil, id: {})
    @sections = actions_for
    @scope = scope
    @id_param = id
  end

  def before_render
    return if @scope == "team"

    @active_section = @sections.find do |section|
      path_prefix = [@scope, section].compact.join("_")
      active_path?(send(:"#{path_prefix}_path", @id_param.presence))
    end

    return unless @active_section && (current_team || @scope == "admin")
    return if @active_section == "record_history"

    full_section = [@scope&.pluralize, @active_section].compact.join("/")
    @action_buttons = render partial: "#{full_section}/action_buttons"
  end
end
