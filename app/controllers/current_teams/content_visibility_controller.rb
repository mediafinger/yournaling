# frozen_string_literal: true

module CurrentTeams
  class ContentVisibilityController < AppCurrentTeamController
    def edit
      @content = ApplicationRecordYidEnabled.fynd(Base64.urlsafe_decode64(params[:id]))
      authorize! @content, to: :read?

      @visibility_states = @content.class::VISIBILITY_STATES - %w[blocked]
    end

    def update
      @content = ApplicationRecordYidEnabled.fynd(Base64.urlsafe_decode64(params[:id]))
      @content.visibility = update_params[:visibility]
      authorize! @content, to: :update?, with: ContentVisibilityPolicy

      @content.class.update_with_event(record: @content, event_params: { team: current_team, user: current_user })

      if @content.changed? || @content.errors.any? # == content still dirty, not saved
        @visibility_states = @content.class::VISIBILITY_STATES - %w[blocked]
        render :edit, status: :unprocessable_content
      else
        redirect_back_or_to current_team_edit_content_visibility_path(@content),
          notice: "#{@content.class.model_name.human} was successfully updated."
      end
    end

    private

    def update_params
      params.permit(:visibility)
    end
  end
end
