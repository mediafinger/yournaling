# frozen_string_literal: true

module Ahoy
  class Visit < ApplicationRecord
    self.table_name = "ahoy_visits"

    belongs_to :user, inverse_of: :visits, optional: true

    has_many :events, class_name: "RecordEvent", inverse_of: :visit, dependent: :delete_all
  end
end
