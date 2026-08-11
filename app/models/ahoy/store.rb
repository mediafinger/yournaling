module Ahoy
  class Store < Ahoy::DatabaseStore
    def visit_model
      Ahoy::Visit # default
    end

    def event_model
      ::RecordEvent
    end
  end
end
