# frozen_string_literal: true

module CurrentTeams
  class ChroniclesController < AppCurrentTeamController
    include ChronicleFormHandling

    def index
      authorize! current_user, to: :index?, with: ChroniclePolicy

      @chronicles = Chronicle.where(team: current_team)
        .includes(entries: :entry)
        .order(start_date: :desc, created_at: :desc)
      Chronicle.preload_attachments(@chronicles)
    end

    def show
      @chronicle = Chronicle.includes(entries: :entry).urlsafe_find!(params[:id])
      Chronicle.preload_attachments(@chronicle)
      authorize! @chronicle
    end

    def new
      @chronicle = Chronicle.new(team: current_team, visibility: "internal")
      authorize! @chronicle
    end

    def edit
      @chronicle = Chronicle.urlsafe_find!(params[:id])
      authorize! @chronicle
    end

    def create
      attrs = chronicle_params
      insight_attrs = ChronicleInsightAttacher.extract_insight_params!(attrs)

      @chronicle = Chronicle.new(attrs.merge(team: current_team))
      authorize! @chronicle

      ActiveRecord::Base.transaction do
        create_with_event(record: @chronicle)
        if @chronicle.persisted?
          ChronicleInsightAttacher.call(chronicle: @chronicle, params: insight_attrs, user: current_user)
        end
      end

      if @chronicle.persisted?
        redirect_to current_team_chronicle_url(@chronicle.urlsafe_id), notice: "Chronicle was successfully created."
      else
        render :new, status: :unprocessable_content
      end
    rescue ActiveRecord::RecordInvalid
      render :new, status: :unprocessable_content
    end

    def update
      attrs = chronicle_params
      insight_attrs = ChronicleInsightAttacher.extract_insight_params!(attrs)

      @chronicle = Chronicle.urlsafe_find!(params[:id])
      authorize! @chronicle
      @chronicle.assign_attributes(attrs)

      ActiveRecord::Base.transaction do
        update_with_event(record: @chronicle)
        unless @chronicle.changed?
          ChronicleInsightAttacher.call(chronicle: @chronicle, params: insight_attrs, user: current_user)
        end
      end

      if @chronicle.changed? # == chronicle still dirty, not saved
        render :edit, status: :unprocessable_content
      else
        redirect_to current_team_chronicle_url(@chronicle.urlsafe_id), notice: "Chronicle was successfully updated."
      end
    rescue ActiveRecord::RecordInvalid
      render :edit, status: :unprocessable_content
    end

    def destroy
      @chronicle = Chronicle.urlsafe_find!(params[:id])
      authorize! @chronicle

      if ActiveRecord::Type::Boolean.new.cast(params[:destroy_orphaned_insights])
        OrphanedInsightsCleanupService.call(post: @chronicle, team: current_team, user: current_user)
      else
        destroy_with_event(record: @chronicle)
      end

      redirect_to current_team_chronicles_url, notice: "Chronicle was successfully destroyed."
    end

    private

    def chronicle_params
      permit_chronicle_params
    end
  end
end
