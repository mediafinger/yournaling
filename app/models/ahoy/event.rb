module Ahoy
  class Event < ApplicationRecord
    include Ahoy::QueryMethods

    self.table_name = "ahoy_events"

    belongs_to :user, inverse_of: :events, optional: true
    belongs_to :visit, inverse_of: :events, optional: true
  end
end
