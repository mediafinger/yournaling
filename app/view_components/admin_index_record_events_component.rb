class AdminIndexRecordEventsComponent < ApplicationComponent
  slim_template <<-SLIM
    div id="record_events"
      @record_events.each do |record_event|
        = render AdminShowRecordEventComponent.new(record_event:)
  SLIM

  def initialize(record_events:)
    @record_events = record_events
  end
end
