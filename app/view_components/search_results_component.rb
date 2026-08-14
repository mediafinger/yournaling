# frozen_string_literal: true

class SearchResultsComponent < ApplicationComponent
  slim_template <<~SLIM
    - if @results.present?
      ul
        - @results.each do |result|
          - if (link = record_link(result)).present?
            li
              = link
              small.content-snippet = result.content.truncate(120)
              i
                > (updated_at:
                = result.searchable.updated_at.to_fs(:db)
                > )
    - elsif @query.present?
      p.empty-notice No results found.
  SLIM

  def initialize(results:, query: nil, scope: "current_team")
    @results = results.presence || []
    @query = query
    @scope = scope
  end

  def record_link(result)
    record = result.searchable
    if record.blank?
      Rails.logger.warn("Stale search index entry: #{result.searchable_type}##{result.searchable_id}")
      return
    end

    link_to("#{record.class.name}: #{result.content.truncate(60)}", record_path(record))
  end

  def record_path(record)
    if @scope == "general"
      if record.is_a?(Team)
        team_home_path(record)
      elsif record.respond_to?(:team) && record.team.present?
        send(:"team_#{record.class.name.tableize.singularize}_path", record.team, record)
      else
        root_path
      end
    else
      send(:"current_team_#{record.class.name.tableize.singularize}_path", record)
    end
  end
end
