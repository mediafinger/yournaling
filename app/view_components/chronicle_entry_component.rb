# frozen_string_literal: true

class ChronicleEntryComponent < ApplicationComponent
  def initialize(chronicle_entry:, scope: "current_team", team: nil)
    @chronicle_entry = chronicle_entry
    @scope = scope
    @team = team || chronicle_entry.team
  end

  def call
    entry = @chronicle_entry.entry
    return if entry.blank?

    type_key = @chronicle_entry.entry_type.underscore
    scope_prefix = case @scope.to_s
                   when "admin" then "admins"
                   when "team", "browse" then "teams"
                   else "current_teams"
                   end

    partial_path = "#{scope_prefix}/#{type_key.pluralize}/#{type_key}"
    unless lookup_context.template_exists?(partial_path, [], true)
      if Rails.env.local?
        raise "Missing partial '#{partial_path}' for ChronicleEntry with entry_type '#{@chronicle_entry.entry_type}'"
      end

      return
    end

    locals = { type_key.to_sym => entry, hide_actions: true }
    locals[:team] = @team if scope_prefix == "teams"

    render partial: partial_path, locals: locals
  end
end
