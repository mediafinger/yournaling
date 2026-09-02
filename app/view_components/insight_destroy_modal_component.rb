# frozen_string_literal: true

class InsightDestroyModalComponent < ApplicationComponent
  def initialize(insight:, name:)
    @insight = insight
    @name = name
  end

  def chronicles
    @chronicles ||= @insight.chronicles
  end

  def memories
    @memories ||= @insight.respond_to?(:memories) ? @insight.memories : Memory.none
  end

  def referenced?
    chronicles.any? || memories.any?
  end

  def destroy_path
    case @insight
    when Picture then current_team_picture_path(@insight)
    when Story then current_team_story_path(@insight)
    when Thought then current_team_thought_path(@insight)
    when Location then current_team_location_path(@insight)
    when Weblink then current_team_weblink_path(@insight)
    end
  end
end
