# frozen_string_literal: true

class AdminIndexRecordEventsComponent < ApplicationComponent
  def initialize(record_events:)
    @record_events = record_events
  end

  attr_reader :record_events
end
