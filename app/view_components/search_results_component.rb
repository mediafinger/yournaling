# frozen_string_literal: true

class SearchResultsComponent < ApplicationComponent
  slim_template <<~SLIM
    - if @results_list.present?
      ul
        - @results_list.each do |result|
          - if (link = record_link(result)).present?
            li
              = link
              - if (ts = result_updated_at(result)).present?
                i
                  > (updated_at:
                  = ts
                  > )
  SLIM

  # TODO: display result["content"] as well ?!

  def initialize(results:, scope: "current_team")
    @results = results
    @scope = scope
  end

  def before_render
    @results_list = normalize_results(@results)
  end

  def record_link(result)
    record = record_for(result)
    return if record.blank?

    link_to("#{record.class.name}: #{record.name}", record_path(record))
  end

  def record_for(result)
    sid = result_searchable_id(result)
    ApplicationRecordYidEnabled.fynd(sid) if sid.present?
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

  def result_searchable_id(result)
    return result.searchable_id if result.respond_to?(:searchable_id)
    return result[:searchable_id] || result["searchable_id"] if result.respond_to?(:key?)

    nil
  end

  def result_updated_at(result)
    raw = if result.respond_to?(:updated_at)
            result.updated_at
          elsif result.respond_to?(:key?)
            result[:updated_at] || result["updated_at"]
          end
    return if raw.blank?

    time = raw.is_a?(Time) || raw.is_a?(DateTime) ? raw : DateTime.parse(raw.to_s)
    time.to_fs(:db)
  end

  private

  def normalize_results(results)
    return [] if results.blank?
    return results.values if results.is_a?(Hash) || results.is_a?(ActionController::Parameters)

    Array(results)
  end
end
