module Ahoy
  class Visit < ApplicationRecord
    self.table_name = "ahoy_visits"

    belongs_to :user, inverse_of: :visits, optional: true

    has_many :events, class_name: "Ahoy::Event", dependent: :nullify
  end
end
