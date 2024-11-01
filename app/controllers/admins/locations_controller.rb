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

    def create
      @location = Location.new(location_params)

      Location.create_with_event(
        record: @location, event_params: { team: nil, user: current_user, done_by_admin: true })

      if @location.persisted?
        redirect_to admin_location_url(@location), notice: "Location was successfully created."
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      @location = Location.urlsafe_find!(params[:id])
      @location.assign_attributes(location_params)

      Location.update_with_event(
        record: @location, event_params: { team: nil, user: current_user, done_by_admin: true })

      if @location.changed? # == location still dirty, not saved
        render :edit, status: :unprocessable_content
      else
        redirect_to admin_location_url(@location), notice: "Location was successfully updated."
      end
    end

    def destroy
      @location = Location.urlsafe_find!(params[:id])

      Location.destroy_with_event(
        record: @location, event_params: { team: nil, user: current_user, done_by_admin: true })

      redirect_to admin_locations_url, notice: "Location was successfully destroyed."
    end

    private

    # switch to dry-validation / dry-contract
    def location_params
      params.require(:location).permit(:address, :country_code, :name, :lat, :long, :url, :team_yid)
    end
  end
end
