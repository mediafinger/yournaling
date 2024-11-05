class AdminIndexRecordHistoryComponent < ApplicationComponent
  slim_template <<~SLIM
    div id="record_history"
      - @record_history.each do |record_history|
        = render AdminShowRecordHistoryComponent.new(record_history:)
  SLIM

  def initialize(record_history:)
    @record_history = record_history
  end
end
