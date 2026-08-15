# frozen_string_literal: true

module Admins
  class ChroniclesController < AdminController
    include ChronicleFormHandling

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
      attrs = chronicle_params
      insight_attrs = Chronicle.extract_insight_params!(attrs)

      @chronicle = Chronicle.new(attrs)

      Chronicle.create_with_event(
        record: @chronicle, event_params: { team: nil, user: current_user, done_by_admin: true }
      )

      if @chronicle.persisted?
        @chronicle.attach_insights(insight_attrs, user: current_user)
        redirect_to admin_chronicle_url(@chronicle), notice: "Chronicle was successfully created."
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      attrs = chronicle_params
      insight_attrs = Chronicle.extract_insight_params!(attrs)

      @chronicle = Chronicle.urlsafe_find!(params[:id])
      @chronicle.assign_attributes(attrs)

      Chronicle.update_with_event(
        record: @chronicle, event_params: { team: nil, user: current_user, done_by_admin: true }
      )

      if @chronicle.changed? # == chronicle still dirty, not saved
        render :edit, status: :unprocessable_content
      else
        @chronicle.attach_insights(insight_attrs, user: current_user)
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
      permit_chronicle_params(additional_keys: [:team_id])
    end
  end
end
