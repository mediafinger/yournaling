class LocationsController < ApplicationController
  skip_before_action :authenticate, only: %i[index show] # allow everyone to see the locations

  def index
    authorize! current_user, to: :index?, with: LocationPolicy

    # locations = authorized_scope(Location.all, type: :relation, as: :current_team_scope)
    locations = Location.all

    @locations = locations
  end

  def show
    @location = Location.urlsafe_find!(params[:id])
    authorize! @location
  end

  def new
    @location = Location.new(team: current_team)
    authorize! @location
  end

  def edit
    @location = Location.urlsafe_find!(params[:id])
    authorize! @location
  end

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

    authorize! @location

    Location.create_with_history(record: @location, history_params: { team: current_team, user: current_user })

    if @location.persisted?
      redirect_to @location, notice: "Location was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @location = Location.urlsafe_find!(params[:id])
    authorize! @location
    @location.assign_attributes(location_params)

    Location.update_with_history(record: @location, history_params: { team: current_team, user: current_user })

    if @location.changed? # == location still dirty, not saved
      render :edit, status: :unprocessable_entity
    else
      redirect_to @location, notice: "Location was successfully updated."
    end
  end

  def destroy
    @location = Location.urlsafe_find!(params[:id])
    authorize! @location

    Location.destroy_with_history(record: @location, history_params: { team: current_team, user: current_user })

    redirect_to locations_url, notice: "Location was successfully destroyed."
  end

  private

  # switch to dry-validation / dry-contract
  def location_params
    params.require(:location).permit(:address, :country_code, :name, :lat, :long, :url)
  end
end
