# frozen_string_literal: true

module Admins
  class ChroniclesController < AdminController
    def index
      @chronicles = Chronicle.includes(chronicle_entries: :entry)
      Chronicle.preload_attachments(@chronicles)
    end

    def show
      @chronicle = Chronicle.includes(chronicle_entries: :entry).urlsafe_find!(params[:id])
      Chronicle.preload_attachments(@chronicle)
    end

    def new
      @chronicle = Chronicle.new(team: current_team, start_date: Date.current, visibility: "internal")
    end

    def edit
      @chronicle = Chronicle.urlsafe_find!(params[:id])
    end

    def create
      @chronicle = Chronicle.new(chronicle_params)

      Chronicle.create_with_event(
        record: @chronicle, event_params: { team: nil, user: current_user, done_by_admin: true }
      )

      if @chronicle.persisted?
        redirect_to admin_chronicle_url(@chronicle), notice: "Chronicle was successfully created."
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      @chronicle = Chronicle.urlsafe_find!(params[:id])
      @chronicle.assign_attributes(chronicle_params)

      Chronicle.update_with_event(
        record: @chronicle, event_params: { team: nil, user: current_user, done_by_admin: true }
      )

      if @chronicle.changed? # == chronicle still dirty, not saved
        render :edit, status: :unprocessable_content
      else
        redirect_to admin_chronicle_url(@chronicle), notice: "Chronicle was successfully updated."
      end
    end

    def destroy
      @chronicle = Chronicle.urlsafe_find!(params[:id])

      Chronicle.destroy_with_event(
        record: @chronicle, event_params: { team: nil, user: current_user, done_by_admin: true }
      )

      redirect_to admin_chronicles_url, notice: "Chronicle was successfully destroyed."
    end

    private

    def chronicle_params
      params.expect(
        chronicle: [:name,
                    :notice,
                    :start_date,
                    :end_date,
                    :visibility,
                    :team_id,
                    { chronicle_entries_attributes: [%i[id entry_type entry_id position _destroy]] }]
      )
    end
  end
end
