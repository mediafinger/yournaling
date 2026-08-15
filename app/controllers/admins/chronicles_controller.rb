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
      attrs = chronicle_params
      picture_id = attrs.delete(:picture_id)
      picture_file = attrs.delete(:picture_file)
      picture_name = attrs.delete(:picture_name)

      @chronicle = Chronicle.new(attrs)

      Chronicle.create_with_event(
        record: @chronicle, event_params: { team: nil, user: current_user, done_by_admin: true }
      )

      if @chronicle.persisted?
        @chronicle.attach_picture(picture_id:, picture_file:, picture_name:, user: current_user)
        redirect_to admin_chronicle_url(@chronicle), notice: "Chronicle was successfully created."
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      attrs = chronicle_params
      picture_id = attrs.delete(:picture_id)
      picture_file = attrs.delete(:picture_file)
      picture_name = attrs.delete(:picture_name)

      @chronicle = Chronicle.urlsafe_find!(params[:id])
      @chronicle.assign_attributes(attrs)

      Chronicle.update_with_event(
        record: @chronicle, event_params: { team: nil, user: current_user, done_by_admin: true }
      )

      if @chronicle.changed? # == chronicle still dirty, not saved
        render :edit, status: :unprocessable_content
      else
        @chronicle.attach_picture(picture_id:, picture_file:, picture_name:, user: current_user)
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
                    :picture_id,
                    :picture_file,
                    :picture_name,
                    { chronicle_entries_attributes: [%i[id entry_type entry_id position _destroy]] }]
      )
    end
  end
end
