class ChroniclesController < ApplicationController
  def index
    authorize! current_user, to: :index?, with: ChroniclePolicy

    # chronicles = authorized_scope(Chronicle.all, type: :relation, as: :current_team_scope)

    @chronicles = Chronicle.with_includes.all
  end

  def show
    @chronicle = Chronicle.with_includes.urlsafe_find!(params[:id])
    authorize! @chronicle
  end

  def new
    @chronicle = Chronicle.new(team: current_team)
    authorize! @chronicle
  end

  def edit
    @chronicle = Chronicle.with_includes.urlsafe_find!(params[:id])
    authorize! @chronicle
  end

  def create
    @chronicle = Chronicle.new(create_params.compact_blank.merge(team: current_team))
    authorize! @chronicle

    Chronicle.create_with_history(record: @chronicle, history_params: { team: current_team, user: current_user })

    if @chronicle.persisted?
      redirect_to @chronicle, notice: "Chronicle was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @chronicle = Chronicle.urlsafe_find!(params[:id])
    authorize! @chronicle
    @chronicle.assign_attributes(update_params.compact_blank)

    Chronicle.update_with_history(record: @chronicle, history_params: { team: current_team, user: current_user })

    if @chronicle.changed? # == chronicle still dirty, not saved
      render :edit, status: :unprocessable_entity
    else
      redirect_to @chronicle, notice: "Chronicle was successfully updated."
    end
  end

  def destroy
    @chronicle = Chronicle.urlsafe_find!(params[:id])
    authorize! @chronicle

    Chronicle.destroy_with_history(record: @chronicle, history_params: { team: current_team, user: current_user })

    redirect_to chronicles_url, notice: "Chronicle was successfully destroyed."
  end

  private

  def create_params
    params.require(:chronicle).permit(:team_yid, :memo, :picture_yid, :location_yid, :weblink_yid)
  end

  def update_params
    params.require(:chronicle).permit(:memo, :picture_yid, :location_yid, :weblink_yid)
  end
end
