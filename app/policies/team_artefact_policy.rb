# frozen_string_literal: true

class TeamArtefactPolicy < ApplicationPolicy
  scope_for :relation do |relation|
    return relation.none unless team.present? && member.present? && member.team == team && member.user == user

    allowed_visibilities = %w[published]
    allowed_visibilities += %w[draft internal archived blocked] if with_role?(:owner, :manager)
    allowed_visibilities += %w[draft internal] if with_role?(:editor)
    allowed_visibilities += %w[internal archived] if with_role?(:publisher)
    allowed_visibilities += %w[internal] if with_role?(:reader)

    visibilities = allowed_visibilities.uniq.presence

    relation.where(team: team, visibility: visibilities)
  end
end
