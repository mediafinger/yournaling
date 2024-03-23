class AdminShowMetaInformationComponent < ApplicationComponent
  erb_template <<-ERB
    <p>
      <strong>created_at:</strong>
      <%= @record.created_at.iso8601 %>
    </p>

    <p>
      <strong>updated_at:</strong>
      <%= @record.updated_at.iso8601 %>
    </p>

    <p>
      <strong>YID:</strong>
      <%= @record.yid %>
    </p>
  ERB

  def initialize(record:)
    @record = record
  end
end
