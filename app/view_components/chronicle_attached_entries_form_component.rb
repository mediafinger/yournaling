# frozen_string_literal: true

class ChronicleAttachedEntriesFormComponent < ApplicationComponent
  slim_template <<~'SLIM'
    - if @chronicle.entries.any?
      fieldset
        legend Attached Entries
        p
          small style="color: var(--pico-muted-color);"
            | Check "Remove" to detach an entry from this chronicle upon saving. Use "Edit" to modify the insight itself.

        div style="display: flex; flex-direction: column; gap: 0.75rem; margin-bottom: 1rem;"
          = @form.fields_for :entries do |entry_form|
            - c_entry = entry_form.object
            - target = c_entry.entry
            - next if target.blank?

            div id=dom_id(c_entry) style="display: flex; align-items: center; justify-content: space-between; gap: 1rem; padding: 0.75rem; border: 1px solid var(--pico-muted-border-color, #e0e0e0); border-radius: 6px;"
              div style="display: flex; align-items: center; gap: 0.75rem; min-width: 0;"
                - case c_entry.entry_type
                - when "Picture"
                  img src=rails_representation_path(target.thumbnail) style="width: 60px; height: 45px; object-fit: cover; border-radius: 4px; flex-shrink: 0;" alt=target.name
                  div style="min-width: 0;"
                    strong style="display: block; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;" = entry_display_title(target)
                    small style="color: var(--pico-muted-color);" = "Picture #{target.date}"
                - when "Location"
                  div style="min-width: 0;"
                    strong style="display: block;" = entry_display_title(target)
                    - if target.address.present?
                      small style="color: var(--pico-muted-color); display: block;" = target.address
                    small style="color: var(--pico-muted-color);" Location
                - when "Thought"
                  div style="min-width: 0;"
                    em style="display: block;" = "“#{target.text.truncate(90)}”#{team_suffix(target)}"
                    small style="color: var(--pico-muted-color);" Thought
                - when "Weblink"
                  div style="min-width: 0;"
                    strong style="display: block;" = entry_display_title(target)
                    small style="color: var(--pico-muted-color); display: block;" = target.url
                    small style="color: var(--pico-muted-color);" Weblink
                - when "Memory"
                  div style="min-width: 0;"
                    em style="display: block;" = "#{target.memo.truncate(90)}#{team_suffix(target)}"
                    small style="color: var(--pico-muted-color);" Memory

              div style="display: flex; align-items: center; gap: 1rem; flex-shrink: 0;"
                - if (edit_path = entry_edit_path(c_entry.entry_type, target))
                  = link_to "Edit", edit_path, target: "_blank", rel: "noopener noreferrer", role: "button", class: "secondary outline", style: "padding: 0.25rem 0.5rem; font-size: 0.8rem;"

                label style="display: flex; align-items: center; gap: 0.35rem; margin-bottom: 0; font-size: 0.85rem; cursor: pointer; color: var(--pico-del-color, #c0392b);"
                  = entry_form.check_box :_destroy, style: "margin-bottom: 0;"
                  | Remove
  SLIM

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
