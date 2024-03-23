class RecordHistoryService
  class << self
    def call(record:, team:, user:, event:, done_by_admin: false)
      #
      # TODO: instead of creating now, push to background job to retry errors
      #
      RecordHistory.create!(
        done_by_admin:,
        event:,
        record_type: record.class::YID_CODE,
        record_yid: record.yid,
        team_yid: done_by_admin ? :admin : team.yid,
        user_yid: user.yid
      )
    end
  end
end
