# frozen_string_literal: true

# A Chronicle rendered as a card: a Browse / Manage header (name + actions),
# the notice, a footer (date + team/creator), and — when expanded — a vertical
# timeline of its entries (or its first picture as a fallback).
#
#   = render ChronicleCardComponent.new(chronicle: chronicle, scope: :browse, team: team)
#   = render ChronicleCardComponent.new(chronicle: chronicle, scope: :manage, full: true)
#
# See MemoryCardComponent for the `scope` / `hide_actions` / `actions` contract.
class ChronicleCardComponent < ApplicationComponent
  include InsightPartialRendering

  SCOPES = %i[browse manage].freeze

  attr_reader :chronicle, :scope, :team, :hide_actions

  def initialize(chronicle:, scope: :manage, team: nil, full: false, hide_actions: false, actions: true)
    super()
    @chronicle = chronicle
    @scope = SCOPES.include?(scope.to_sym) ? scope.to_sym : :manage
    @team = team || chronicle.team
    @full = full
    @hide_actions = hide_actions
    @actions = actions
  end

  def actions?
    @actions
  end

  def expanded?
    @full || (helpers.controller_name == "chronicles" && helpers.action_name == "show")
  end

  def header_component
    if scope == :browse
      BrowseHeaderComponent.new(record: chronicle, team: team, full: @full)
    else
      ManageHeaderComponent.new(record: chronicle, hide_actions: hide_actions, full: @full)
    end
  end

  def entry_scope
    scope == :browse ? "team" : "current_team"
  end

  def static_meta
    [chronicle.try(:start_date), team&.name].compact_blank.join(" · ")
  end
end
