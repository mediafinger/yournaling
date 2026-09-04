# frozen_string_literal: true

# A Memory rendered as a card: no header (Memory has no name and always shows
# the whole memo, so there's nothing to open or link), a footer (date, Rewrite,
# team/creator, and — manage scope — the visibility control), the memo in
# full, and its attached insights (picture / thought / location / weblink).
#
#   = render MemoryCardComponent.new(memory: memory, scope: :browse, team: team)
#   = render MemoryCardComponent.new(memory: memory, scope: :manage)
#
# scope:        :browse (public `teams/*` views) or :manage (`current_teams/*`)
# hide_actions: suppress the footer's Rewrite / visibility control (embedded
#               contexts — a memory shown inside a chronicle's own card)
class MemoryCardComponent < ApplicationComponent
  include InsightPartialRendering

  SCOPES = %i[browse manage].freeze
  ATTACHMENTS = %i[picture thought location weblink].freeze

  attr_reader :memory, :scope, :team, :hide_actions

  def initialize(memory:, scope: :manage, team: nil, hide_actions: false)
    super()
    @memory = memory
    @scope = SCOPES.include?(scope.to_sym) ? scope.to_sym : :manage
    @team = team || memory.team
    @hide_actions = hide_actions
  end

  def attachments
    ATTACHMENTS.filter_map { |name| memory.public_send(name) }
  end
end
