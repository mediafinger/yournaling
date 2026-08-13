# frozen_string_literal: true

class SearchResultsComponent < ApplicationComponent
  slim_template <<~SLIM
    - if @results.present?
      ul
        - @results.each do |result|
          li
            = @record_links[result["searchable_id"]]
            i
              > (updated_at:
              = DateTime.parse(result['updated_at']).to_fs(:db)
              > )
  SLIM

  # TODO: display result["content"] as well ?!

  def initialize(results:, scope: "current_team")
    @results = results
    @scope = scope
  end

  def before_render
    @record_links = @results&.each_with_object({}) do |result, hash|
      record = ApplicationRecordYidEnabled.fynd(result["searchable_id"])
      next if record.blank?

      link_text = "#{record.class.name}: #{record.name}"
      link_path = if @scope == "general"
                    if record.respond_to?(:team) && record.team.present?
                      send(:"team_#{record.class.name.tableize.singularize}_path", record.team, record)
                    elsif record.is_a?(Team)
                      team_home_path(record)
                    else
                      root_path
                    end
                  else
                    send(:"current_team_#{record.class.name.tableize.singularize}_path", record)
                  end
      hash[result["searchable_id"]] = link_to(link_text, link_path)
    end
  end
end
