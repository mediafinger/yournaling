class AdminIndexRecordHistoryComponent < ApplicationComponent
  erb_template <<~ERB
    <div id="record_history">
      <% @record_history.each do |record_history| %>
        <%= render AdminShowRecordHistoryComponent.new(record_history:) %>
      <% end %>
    </div>
  ERB

  def initialize(record_history:)
    @record_history = record_history
  end
end
