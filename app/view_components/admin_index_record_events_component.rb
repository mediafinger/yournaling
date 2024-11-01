class AdminIndexRecordEventsComponent < ApplicationComponent
  erb_template <<-ERB
    <div id="record_events">
      <% @record_events.each do |record_event| %>
        <%= render AdminShowRecordEventComponent.new(record_event:) %>
      <% end %>
    </div>
  ERB

  def initialize(record_events:)
    @record_events = record_events
  end
end
