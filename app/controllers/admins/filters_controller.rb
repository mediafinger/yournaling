module Admins
  class FiltersController < AdminController
    FILTERS = {
      "klass_name" => nil,
      "team_yid" => nil,
      "user_yid" => nil,
      "yid" => nil,
      "name" => nil,
      "record_type" => nil,
      "record_yid" => nil,
      "event" => nil,
    }.freeze

    def new
      @filters = FILTERS.merge(params.to_unsafe_h[:filters].presence || {})
      @results = params.to_unsafe_h[:results].presence
    end

    def create
      filters = FILTERS.merge(params.to_unsafe_h[:filters].presence || {})

      scope = filters["klass_name"].constantize
      scope = scope.where(team_yid: filters["team_yid"]) if filters["team_yid"].presence
      scope = scope.where(user_yid: filters["user_yid"]) if filters["user_yid"].presence
      scope = scope.where(yid: filters["yid"]) if filters["yid"].presence
      scope = scope.where(name: filters["name"]) if filters["name"].presence
      scope = scope.where(record_type: filters["record_type"]) if filters["record_type"].presence
      scope = scope.where(record_yid: filters["record_yid"]) if filters["record_yid"].presence
      scope = scope.where(event: filters["event"]) if filters["event"].presence
      results = scope.reorder(updated_at: :desc).limit(25)

      redirect_to admin_new_filter_path(filters: filters.as_json, results: results.as_json)
    end
  end
end
