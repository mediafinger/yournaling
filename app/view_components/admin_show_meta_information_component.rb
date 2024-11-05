class AdminShowMetaInformationComponent < ApplicationComponent
  slim_template <<~SLIM
    p
      strong created_at:
      = @record.created_at.iso8601
    p
      strong updated_at:
      = @record.updated_at.iso8601
    p
      strong ID:
      = @record.id
  SLIM

  def initialize(record:)
    @record = record
  end
end
