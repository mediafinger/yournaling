# frozen_string_literal: true

class ChronicleAttachedEntriesFormComponent < ApplicationComponent
  def initialize(form:, scope: "current_team")
    @form = form
    @chronicle = form.object
    @scope = scope
  end

  def entry_display_title(target)
    if @scope == "admin" && target.respond_to?(:team) && target.team
      "#{target.name} (#{target.team.name})"
    else
      target.name
    end
  end

  def team_suffix(target)
    if @scope == "admin" && target.respond_to?(:team) && target.team
      " (#{target.team.name})"
    else
      ""
    end
  end

  def entry_edit_path(entry_type, target)
    type_name = entry_type.underscore
    helper_name = case @scope
                  when "admin" then "edit_admin_#{type_name}_path"
                  else "edit_current_team_#{type_name}_path"
                  end
    send(helper_name, target) if respond_to?(helper_name)
  end
end
