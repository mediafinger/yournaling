# frozen_string_literal: true

# Based on team_artefacts VIEW (not a table)

class TeamArtefact < ApplicationRecord
  self.primary_key = :artefact_id

  belongs_to :team
  belongs_to :artefact, polymorphic: true, foreign_type: :artefact_type

  scope :for_team, ->(team) { where(team: team) }
  scope :chronological, -> { order(updated_at: :desc) }

  def readonly?
    true
  end
end
