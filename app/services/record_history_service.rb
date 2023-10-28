class RecordHistoryService
  class << self
    def call(record:, team:, user:, event:)
      #
      # TODO: instead of creating now, push to background job to retry errors
      #
      RecordHistory.create!(
        event:,
        record_type: record.class::YID_CODE,
        record_yid: record.yid,
        team_yid: team.yid,
        user_yid: user.yid
      )
    end
  end
end
