module CurrentTeams
  class ChroniclesController < AppCurrentTeamController
    def index
      authorize! current_user, to: :index?, with: ChroniclePolicy

      # chronicles = authorized_scope(Chronicle.all, type: :relation, as: :current_team_scope)

      @chronicles = current_team_scope(Chronicle).includes(:team, :picture, :location, :weblink).all
    end

    def show
      @chronicle = current_team_scope(Chronicle).urlsafe_find!(params[:id])
      authorize! @chronicle
    end

    def new
      @chronicle = Chronicle.new(team: current_team)
      authorize! @chronicle
    end

    def edit
      @chronicle = current_team_scope(Chronicle).urlsafe_find!(params[:id])
      authorize! @chronicle
    end

    def create
      @chronicle = Chronicle.new(chronicle_params.compact_blank.merge(team: current_team))
      authorize! @chronicle

      Chronicle.create_with_history(record: @chronicle, history_params: { team: current_team, user: current_user })

      if @chronicle.persisted?
        redirect_to current_team_chronicle_url(@chronicle), notice: "Chronicle was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      @chronicle = current_team_scope(Chronicle).urlsafe_find!(params[:id])
      authorize! @chronicle
      @chronicle.assign_attributes(chronicle_params.compact_blank)

      Chronicle.update_with_history(record: @chronicle, history_params: { team: current_team, user: current_user })

      if @chronicle.changed? # == chronicle still dirty, not saved
        render :edit, status: :unprocessable_entity
      else
        redirect_to current_team_chronicle_url(@chronicle), notice: "Chronicle was successfully updated."
      end
    end

    def destroy
      @chronicle = current_team_scope(Chronicle).urlsafe_find!(params[:id])
      authorize! @chronicle

      Chronicle.destroy_with_history(record: @chronicle, history_params: { team: current_team, user: current_user })

      redirect_to current_team_chronicles_url, notice: "Chronicle was successfully destroyed."
    end

    private

    def chronicle_params
      params.require(:chronicle).permit(
        :name,
        :notes,
        chronicle_locations_attributes: %i[location_yid _destroy], # accepts_nested_attributes_for
        chronicle_pictures_attributes: %i[picture_yid _destroy], # accepts_nested_attributes_for
        chronicle_weblinks_attributes: %i[weblink_yid _destroy] # accepts_nested_attributes_for
      )
    end
  end
end
