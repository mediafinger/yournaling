# frozen_string_literal: true

# A Memory rendered as a card: a Browse / Manage header (no title — Memory
# has no name, and repeating the memo there would just duplicate the body —
# actions only), a footer (date + team/creator), the memo, and its attached
# insights (picture / thought / location / weblink).
#
#   = render MemoryCardComponent.new(memory: memory, scope: :browse, team: team)
#   = render MemoryCardComponent.new(memory: memory, scope: :manage)
#
# scope:        :browse (public `teams/*` views) or :manage (`current_teams/*`)
# hide_actions: suppress the manage header's action buttons (embedded contexts)
# actions:      `false` renders a plain meta line instead of the header component
#               — for previews / static contexts with no auth (see
#               TODO_UI_DESIGN.md Phase 4 → "Records — component previews").
class MemoryCardComponent < ApplicationComponent
  include InsightPartialRendering

  SCOPES = %i[browse manage].freeze
  ATTACHMENTS = %i[picture thought location weblink].freeze

  attr_reader :memory, :scope, :team, :hide_actions

  def initialize(memory:, scope: :manage, team: nil, hide_actions: false, actions: true)
    super()
    @memory = memory
    @scope = SCOPES.include?(scope.to_sym) ? scope.to_sym : :manage
    @team = team || memory.team
    @hide_actions = hide_actions
    @actions = actions
  end

  def actions?
    @actions
  end

  def header_component
    if scope == :browse
      BrowseHeaderComponent.new(record: memory, team: team)
    else
      ManageHeaderComponent.new(record: memory, hide_actions: hide_actions)
    end
  end

  def static_meta
    [memory.created_at&.to_date, team&.name].compact_blank.join(" · ")
  end

  def attachments
    ATTACHMENTS.filter_map { |name| memory.public_send(name) }
  end
end
