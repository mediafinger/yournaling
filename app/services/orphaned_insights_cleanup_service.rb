# frozen_string_literal: true

class OrphanedInsightsCleanupService
  class << self
    def call(post:, team:, user:)
      new(post:, team:, user:).call
    end
  end

  def initialize(post:, team:, user:)
    @post = post
    @team = team
    @user = user
  end

  def call
    insights = attached_insights

    # TODO: instead of running this in a transaction, we could destroy the post
    # in the controller and then queue this service in a background job
    ApplicationRecord.transaction do
      ApplicationRecordYidEnabled.destroy_with_event(record: @post, event_params: { team: @team, user: @user })

      insights.each do |insight|
        next if insight.destroyed?
        next unless orphaned?(insight)

        ApplicationRecordYidEnabled.destroy_with_event(record: insight, event_params: { team: @team, user: @user })
      end
    end
  end

  private

  def attached_insights
    case @post
    when Memory
      [@post.picture, @post.thought, @post.location, @post.weblink].compact
    when Chronicle
      @post.entries.includes(:entry).filter_map(&:entry).select do |entry|
        entry.is_a?(Picture) || entry.is_a?(Thought) || entry.is_a?(Location) || entry.is_a?(Weblink)
      end
    else
      []
    end
  end

  def orphaned?(insight)
    has_memories = insight.memories.exists?
    has_chronicles = insight.chronicle_entries.exists?

    !has_memories && !has_chronicles
  end
end
