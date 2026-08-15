# frozen_string_literal: true

module CurrentTeams
  class ChroniclesController < AppCurrentTeamController
    def index
      authorize! current_user, to: :index?, with: ChroniclePolicy

      @chronicles = Chronicle.where(team: current_team)
        .includes(chronicle_entries: :entry)
        .order(start_date: :desc, created_at: :desc)
      Chronicle.preload_attachments(@chronicles)
    end

    def show
      @chronicle = Chronicle.includes(chronicle_entries: :entry).urlsafe_find!(params[:id])
      Chronicle.preload_attachments(@chronicle)
      authorize! @chronicle
    end

    def new
      @chronicle = Chronicle.new(team: current_team, start_date: Date.current, visibility: "internal")
      @team_pictures = Picture.where(team: current_team).with_attached_file.order(created_at: :desc)
      authorize! @chronicle
    end

    def edit
      @chronicle = Chronicle.urlsafe_find!(params[:id])
      @team_pictures = Picture.where(team: current_team).with_attached_file.order(created_at: :desc)
      authorize! @chronicle
    end

    def create
      attrs = chronicle_params
      picture_id = attrs.delete(:picture_id)
      picture_file = attrs.delete(:picture_file)
      picture_name = attrs.delete(:picture_name)

      @chronicle = Chronicle.new(attrs.merge(team: current_team))
      authorize! @chronicle

      create_with_event(record: @chronicle)

      if @chronicle.persisted?
        @chronicle.attach_picture(picture_id:, picture_file:, picture_name:, user: current_user)
        redirect_to current_team_chronicle_url(@chronicle.urlsafe_id), notice: "Chronicle was successfully created."
      else
        @team_pictures = Picture.where(team: current_team).with_attached_file.order(created_at: :desc)
        render :new, status: :unprocessable_content
      end
    end

    def update
      attrs = chronicle_params
      picture_id = attrs.delete(:picture_id)
      picture_file = attrs.delete(:picture_file)
      picture_name = attrs.delete(:picture_name)

      @chronicle = Chronicle.urlsafe_find!(params[:id])
      authorize! @chronicle
      @chronicle.assign_attributes(attrs)

      update_with_event(record: @chronicle)

      if @chronicle.changed? # == chronicle still dirty, not saved
        @team_pictures = Picture.where(team: current_team).with_attached_file.order(created_at: :desc)
        render :edit, status: :unprocessable_content
      else
        @chronicle.attach_picture(picture_id:, picture_file:, picture_name:, user: current_user)
        redirect_to current_team_chronicle_url(@chronicle.urlsafe_id), notice: "Chronicle was successfully updated."
      end
    end

    def destroy
      @chronicle = Chronicle.urlsafe_find!(params[:id])
      authorize! @chronicle

      destroy_with_event(record: @chronicle)

      redirect_to current_team_chronicles_url, notice: "Chronicle was successfully destroyed."
    end

    private

    def chronicle_params
      params.expect(
        chronicle: [:name,
                    :notice,
                    :start_date,
                    :end_date,
                    :visibility,
                    :picture_id,
                    :picture_file,
                    :picture_name,
                    { chronicle_entries_attributes: [%i[id entry_type entry_id position _destroy]] }]
      )
    end
  end
end
