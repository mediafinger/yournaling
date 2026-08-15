# frozen_string_literal: true

module Teams
  class ChroniclesController < AppTeamsController
    def index
      @chronicles = records_scope(Chronicle.includes(chronicle_entries: :entry))
      Chronicle.preload_attachments(@chronicles)

      render "teams/chronicles/index"
    end

    def show
      @chronicle = record(Chronicle.includes(chronicle_entries: :entry), params[:id])
      Chronicle.preload_attachments(@chronicle)

      render "teams/chronicles/show"
    end
  end
end
