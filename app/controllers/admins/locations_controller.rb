module Admins
  class LocationsController < AdminController
    def index
      @locations = Location.all
    end

    def show
      @location = Location.urlsafe_find!(params[:id])
    end

    def new
      @location = Location.new(team: current_team)
    end

    def edit
      @location = Location.urlsafe_find!(params[:id])
    end

    # TODO: create with either address + geocoding for lat & long coordinates
    # TODO: or create with lat & long coordinates and reverse geocoding for address
    def create
      @location = Location.new(
        address: location_params[:address] || {}, # TODO: validate Hash / JSON structure
        country_code: location_params[:country_code],
        lat: location_params[:lat],
        long: location_params[:long],
        name: location_params[:name],
        team: current_team,
        url: location_params[:url] # TODO: validate URL, or ensure it returns 200 ?!
      )

      Location.transaction do
        @location.save &&
          RecordHistoryService.call(
            record: @location, team: current_team, user: current_user, event: :created, done_by_admin: true)
      end

      if @location.persisted?
        redirect_to admin_location_url(@location), notice: "Location was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      @location = Location.urlsafe_find!(params[:id])

      Location.transaction do
        @location.update(location_params) &&
          RecordHistoryService.call(
            record: @location, team: current_team, user: current_user, event: :updated, done_by_admin: true)
      end

      if @location.changed? # == location still dirty, not saved
        render :edit, status: :unprocessable_entity
      else
        redirect_to admin_location_url(@location), notice: "Location was successfully updated."
      end
    end

    def destroy
      @location = Location.urlsafe_find!(params[:id])

      Location.transaction do
        RecordHistoryService.call(
          record: @location, team: current_team, user: current_user, event: :deleted, done_by_admin: true)
        @location.destroy!
      end

      redirect_to admin_locations_url, notice: "Location was successfully destroyed."
    end

    private

    # switch to dry-validation / dry-contract
    def location_params
      params.require(:location).permit(:address, :country_code, :name, :lat, :long, :url)
    end
  end
end
