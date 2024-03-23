module Admins
  class WeblinksController < AdminController
    def index
      @weblinks = Weblink.all
    end

    def show
      @weblink = Weblink.urlsafe_find!(params[:id])
    end

    def new
      @weblink = Weblink.new(team: current_team)
    end

    def edit
      @weblink = Weblink.urlsafe_find!(params[:id])
    end

    # TODO: set preview_snippet by calling the URL once to also validate it
    def create
      @weblink = Weblink.new(
        url: weblink_params[:url],
        name: weblink_params[:name],
        description: weblink_params[:description],
        team: current_team
      )

      Weblink.transaction do
        @weblink.save &&
          RecordHistoryService.call(
            record: @weblink, team: current_team, user: current_user, event: :created, done_by_admin: true)
      end

      if @weblink.persisted?
        redirect_to admin_weblink_url(@weblink), notice: "Weblink was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      @weblink = Weblink.urlsafe_find!(params[:id])

      Weblink.transaction do
        @weblink.update(weblink_params) &&
          RecordHistoryService.call(
            record: @weblink, team: current_team, user: current_user, event: :updated, done_by_admin: true)
      end

      if @weblink.changed? # == weblink still dirty, not saved
        render :edit, status: :unprocessable_entity
      else
        redirect_to admin_weblink_url(@weblink), notice: "Weblink was successfully updated."
      end
    end

    def destroy
      @weblink = Weblink.urlsafe_find!(params[:id])

      Weblink.transaction do
        RecordHistoryService.call(
          record: @weblink, team: current_team, user: current_user, event: :deleted, done_by_admin: true)
        @weblink.destroy!
      end

      redirect_to admin_weblinks_url, notice: "Weblink was successfully destroyed."
    end

    private

    def weblink_params
      params.require(:weblink).permit(:url, :name, :description)
    end
  end
end
