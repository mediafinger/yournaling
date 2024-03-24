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
      @weblink = Weblink.new(weblink_params)

      Weblink.create_with_history(record: @weblink, history_params: { team: nil, user: current_user, done_by_admin: true })

      if @weblink.persisted?
        redirect_to admin_weblink_url(@weblink), notice: "Weblink was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      @weblink = Weblink.urlsafe_find!(params[:id])
      @weblink.assign_attributes(weblink_params)

      Weblink.update_with_history(record: @weblink, history_params: { team: nil, user: current_user, done_by_admin: true })

      if @weblink.changed? # == weblink still dirty, not saved
        render :edit, status: :unprocessable_entity
      else
        redirect_to admin_weblink_url(@weblink), notice: "Weblink was successfully updated."
      end
    end

    def destroy
      @weblink = Weblink.urlsafe_find!(params[:id])

      Weblink.destroy_with_history(record: @weblink, history_params: { team: nil, user: current_user, done_by_admin: true })

      redirect_to admin_weblinks_url, notice: "Weblink was successfully destroyed."
    end

    private

    def weblink_params
      params.require(:weblink).permit(:url, :name, :description, :team_yid)
    end
  end
end
