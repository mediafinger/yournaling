# frozen_string_literal: true

# A Chronicle rendered as a card: a header (just the name, linking to the show
# page — see BrowseHeaderComponent / ManageHeaderComponent), the notice, a
# footer (date, Rewrite, team/creator, and — manage scope — the visibility
# control; browse scope instead gets a "Show more" toggle when there's more to
# reveal), and — when expanded — a vertical timeline of its entries (or its
# first picture as a fallback).
#
#   = render ChronicleCardComponent.new(chronicle: chronicle, scope: :browse, team: team)
#   = render ChronicleCardComponent.new(chronicle: chronicle, scope: :manage, full: true)
class ChronicleCardComponent < ApplicationComponent
  include InsightPartialRendering

  SCOPES = %i[browse manage].freeze

  attr_reader :chronicle, :scope, :team, :hide_actions

  def initialize(chronicle:, scope: :manage, team: nil, full: false, hide_actions: false)
    super()
    @chronicle = chronicle
    @scope = SCOPES.include?(scope.to_sym) ? scope.to_sym : :manage
    @team = team || chronicle.team
    @full = full
    @hide_actions = hide_actions
  end

  def expanded?
    @full || (helpers.controller_name == "chronicles" && helpers.action_name == "show")
  end

  def header_component
    if scope == :browse
      BrowseHeaderComponent.new(record: chronicle, team: team, full: @full)
    else
      ManageHeaderComponent.new(record: chronicle, hide_actions: hide_actions, full: @full, actions_in_header: false)
    end
  end

  def entry_scope
    scope == :browse ? "team" : "current_team"
  end

  # Loaded once and reused by both #show_more? and the template's timeline —
  # also lets Chronicle#first_picture use the loaded association instead of a
  # separate query (see Chronicle#first_picture).
  def entries
    @entries ||= chronicle.entries.to_a
  end

  # Browse-mode feed cards hide the entries timeline behind a "Show more"
  # toggle (see app/javascript/controllers/card_expand_controller.js) instead
  # of rendering it outright — only worth offering when there's one to reveal.
  def show_more?
    scope == :browse && !expanded? && entries.any?
  end
end
