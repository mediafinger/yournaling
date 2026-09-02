# frozen_string_literal: true

# The "Insights" nav menu (pictures / locations / thoughts / weblinks).
class InsightsDropdownComponent < ApplicationComponent
  SECTIONS = {
    admin: %w[pictures locations thoughts weblinks],
    current_team: %w[pictures thoughts locations weblinks],
  }.freeze

  def initialize(scope: :current_team)
    @scope = scope.to_sym
  end

  # [[label, path], …]
  def items
    prefix = @scope == :admin ? "admin" : "current_team"
    SECTIONS.fetch(@scope, SECTIONS[:current_team]).map do |section|
      [section.titleize, public_send(:"#{prefix}_#{section}_path")]
    end
  end

  def active?
    items.any? { |(_label, path)| active_path?(path) }
  end
end
