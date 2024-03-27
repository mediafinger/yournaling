module Teams
  class LocationsController < AppTeamsController
    def show
      @location = record(Location, params[:id])

      render "teams/locations/show"
    end
  end
end
