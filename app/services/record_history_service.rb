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
        record_id: record.id,
        team_id: done_by_admin ? :admin : team.id,
        user_id: user.id
      )

      # Is it possible to ENQUEUE in background job - or is then context missing?
      # Do not run this in the transaction!!
      #
      # ahoy.track(
      #   "RecordHistory #{record.class::YID_CODE} #{event}",
      #   { user_id: user.id , history_id: rh.id}
      # );
    end
  end
end
