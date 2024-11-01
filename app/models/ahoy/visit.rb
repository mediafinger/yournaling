module Ahoy
  class Visit < ApplicationRecord
    self.table_name = "ahoy_visits"

    belongs_to :user, inverse_of: :visits, foreign_key: "user_yid"

    has_many :events, class_name: "RecordEvent", inverse_of: :visit, dependent: :delete_all
  end
end
