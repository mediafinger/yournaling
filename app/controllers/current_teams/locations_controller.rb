# frozen_string_literal: true

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
      @location = current_team.locations.new
      authorize! @location
    end

    def edit
      @location = current_team_scope(Location).urlsafe_find!(params[:id])
      authorize! @location
    end

    def create
      @location = current_team.locations.new(location_params)
      authorize! @location

      create_with_event(record: @location)

      respond_to do |format|
        if @location.persisted?
          format.html { redirect_to current_team_location_url(@location), notice: "Location was successfully created." }
          format.json do
            render json: { id: @location.id, name: @location.name, country_code: @location.country_code, type: "location" },
              status: :created
          end
        else
          format.html { render :new, status: :unprocessable_content }
          format.json { render json: { errors: @location.errors.full_messages }, status: :unprocessable_content }
        end
      end
    end

    def update
      @location = current_team_scope(Location).urlsafe_find!(params[:id])
      authorize! @location
      @location.assign_attributes(location_params)

      update_with_event(record: @location)

      if @location.changed? # == location still dirty, not saved
        render :edit, status: :unprocessable_content
      else
        redirect_to current_team_location_url(@location), notice: "Location was successfully updated."
      end
    end

    def destroy
      @location = current_team_scope(Location).urlsafe_find!(params[:id])
      authorize! @location

      if @location.memories.exists? || @location.chronicle_entries.exists?
        redirect_to edit_current_team_location_url(@location),
          alert: "Location cannot be destroyed because it is still referenced by other content."
      else
        destroy_with_event(record: @location)
        redirect_to current_team_locations_url, notice: "Location was successfully destroyed."
      end
    end

    private

    # switch to dry-validation / dry-contract
    def location_params
      params.expect(location: %i[address country_code name date lat long url map_url])
    end
  end
end
