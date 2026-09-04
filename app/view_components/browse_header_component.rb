# frozen_string_literal: true

# The header of a record card in the browse (public) area: just the record
# name, rendered as a plain-looking link to its show page — underlines only
# on hover (see .yui-link--cover) — unless we're already on that page, or
# there's nowhere to link to. Actions (Rewrite, visibility) live in the card
# footer now — see RecordFooterComponent.
#
# Used by ChronicleCardComponent only; Memory has no header at all, and the
# browse insight partials (teams/*) don't use this component.
class BrowseHeaderComponent < ApplicationComponent
  def initialize(record:, team: nil, title: nil, full: false)
    super()
    @record = record
    @team = team || record.try(:team)
    @title = title
    @full = full
  end

  def title
    return @title if @title.present?

    @record.try(:name).presence || @record.class.model_name.human
  end

  def show_path
    case @record
    when Chronicle
      helpers.team_chronicle_path(@team, @record)
    when Memory
      helpers.team_memory_path(@team, @record)
    when Picture
      helpers.team_picture_path(@team, @record)
    end
  end

  def linkable?
    return false if @full
    # In-memory records (e.g. /example, which is reachable in production and
    # so can't use FactoryBot's build_stubbed to fake an id) have no route.
    return false unless @record.persisted? && @team&.persisted?
    return false if controller_name == @record.class.model_name.plural && action_name == "show"

    show_path.present?
  end

  private

  def controller_name
    helpers.controller.controller_name
  end

  def action_name
    helpers.controller.action_name
  end
end
