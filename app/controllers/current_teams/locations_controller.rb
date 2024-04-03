module CurrentTeams
  class LocationsController < AppCurrentTeamController
    def index
      locations = current_team_scope(Location)

      authorize! current_user, to: :index?, with: LocationPolicy
      # TODO
      # locations = authorized_scope(Location.all, type: :relation, as: :current_team_scope)

      @locations = locations
    end

    def show
      @location = current_team_scope(Location).urlsafe_find!(params[:id])
      authorize! @location
    end

    def new
      @location = current_team.locations.new(location_params)
      authorize! @location
    end

    def edit
      @location = current_team_scope(Location).urlsafe_find!(params[:id])
      authorize! @location
    end

    def create
      @location = current_team.locations.new(location_params)
      authorize! @location

      create_with_history(record: @location)

      if @location.persisted?
        redirect_to current_team_location_path(@location), notice: "Location was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      @location = current_team_scope(Location).urlsafe_find!(params[:id])
      authorize! @location
      @location.assign_attributes(location_params)

      update_with_history(record: @location)

      if @location.changed? # == location still dirty, not saved
        render :edit, status: :unprocessable_entity
      else
        redirect_to current_team_location_path(@location), notice: "Location was successfully updated."
      end
    end

    def destroy
      @location = current_team_scope(Location).urlsafe_find!(params[:id])
      authorize! @location

      destroy_with_history(record: @location)

      redirect_to current_team_locations_path, notice: "Location was successfully destroyed."
    end

    private

    # switch to dry-validation / dry-contract
    def location_params
      params.require(:location).permit(:address, :country_code, :name, :lat, :long, :url)
    end
  end
end
