# frozen_string_literal: true

class SearchResultsComponent < ApplicationComponent
  slim_template <<~SLIM
    - if @results.present?
      ul
        - @results.each do |result|
          - if (link = record_link(result)).present?
            li
              = link
              i
                > (updated_at:
                = result.updated_at.to_fs(:db)
                > )
    - elsif @query.present?
      p.empty-notice No results found.
  SLIM

  # TODO: display result["content"] as well ?!

  def initialize(results:, query: nil, scope: "current_team")
    @results = results.presence || []
    @query = query
    @scope = scope
  end

  def record_link(result)
    record = ApplicationRecordYidEnabled.fynd(result.searchable_id)
    return if record.blank?

    link_to("#{record.class.name}: #{record.name}", record_path(record))
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
