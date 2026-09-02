# frozen_string_literal: true

# Shared by MemoryCardComponent / ChronicleCardComponent: render a nested
# insight (picture / thought / location / weblink) through the right per-area
# partial for the card's `scope`.
module InsightPartialRendering
  private

  def insight_partial_path(record)
    type = record.model_name.singular
    "#{scope == :browse ? 'teams' : 'current_teams'}/#{type.pluralize}/#{type}"
  end

  def insight_partial_locals(record)
    key = record.model_name.singular.to_sym
    if scope == :browse
      { key => record, team: team }
    else
      { key => record, hide_actions: true }
    end
  end
end
