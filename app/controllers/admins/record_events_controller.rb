module Admins
  class RecordEventsController < AdminController
    def index
      @record_events =
        if params[:record_yid]
          RecordEvent.where(record_type:, record_yid:).order(created_at: :desc).limit(10)
        else
          RecordEvent.where(user_yid: current_user.yid).order(created_at: :desc).limit(10)
        end
    end

    private

    def record_type
      record_yid.split("_").first
    end

    def record_yid
      Base64.urlsafe_decode64(params[:record_yid])
    end
  end
end
