# frozen_string_literal: true

module VisibilityConstrainedByParents
  extend ActiveSupport::Concern

  included do
    validate :validate_visibility_not_limited_by_parents, if: :visibility_changed?
  end

  def highest_parent_visibility_level(except_parent: nil)
    parent_levels = []

    if respond_to?(:chronicles)
      chronicles_list = persisted? ? chronicles.reload : chronicles
      chronicles_list.each do |chronicle|
        next if except_parent && chronicle.id == except_parent.id

        parent_levels << chronicle.visibility_level
      end
    end

    if respond_to?(:memories)
      memories_list = persisted? ? memories.reload : memories
      memories_list.each do |memory|
        next if except_parent && memory.id == except_parent.id

        parent_levels << memory.visibility_level
      end
    end

    parent_levels.max || 0
  end

  private

  def validate_visibility_not_limited_by_parents
    return if visibility.blank?

    if respond_to?(:chronicles)
      chronicles_list = persisted? ? chronicles.reload : chronicles
      chronicles_list.each do |chronicle|
        next unless chronicle.more_permissive_than?(visibility)

        errors.add(
          :visibility,
          "cannot be limited to '#{visibility}' because it belongs to " \
          "Chronicle '#{chronicle.name}' with visibility '#{chronicle.visibility}'"
        )
      end
    end

    return unless respond_to?(:memories)

    memories_list = persisted? ? memories.reload : memories
    memories_list.each do |memory|
      next unless memory.more_permissive_than?(visibility)

      errors.add(
        :visibility,
        "cannot be limited to '#{visibility}' because it belongs to " \
        "Memory '#{memory.memo.truncate(40)}' with visibility '#{memory.visibility}'"
      )
    end
  end
end
