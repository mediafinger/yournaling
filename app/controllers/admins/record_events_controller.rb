module Admins
  class RecordEventsController < AdminController
    def index
      @record_events =
        if params[:record_id]
          RecordEvent.where(record_type:, record_id:).order(created_at: :desc).limit(10)
        else
          RecordEvent.where(user_id: current_user.id).order(created_at: :desc).limit(10)
        end
    end

    private

    def record_type
      record_id.split("_").first
    end

    def record_id
      Base64.urlsafe_decode64(params[:record_id])
    end
  end
end
