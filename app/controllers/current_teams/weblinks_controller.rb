# TODO

module CurrentTeams
  class WeblinksController < AppCurrentTeamController
    skip_before_action :authenticate, only: %i[index show] # allow everyone to see the weblinks

    def index
      authorize! current_user, to: :index?, with: WeblinkPolicy

      # weblinks = authorized_scope(Weblink.all, type: :relation, as: :current_team_scope)
      weblinks = Weblink.all

      @weblinks = weblinks
    end

    def show
      @weblink = Weblink.urlsafe_find!(params[:id])
      authorize! @weblink
    end

    def new
      @weblink = Weblink.new(team: current_team)
      authorize! @weblink
    end

    def edit
      @weblink = Weblink.urlsafe_find!(params[:id])
      authorize! @weblink
    end

    # TODO: set preview_snippet by calling the URL once to also validate it
    def create
      @weblink = Weblink.new(
        url: weblink_params[:url],
        name: weblink_params[:name],
        description: weblink_params[:description],
        team: current_team
      )

      authorize! @weblink

      Weblink.create_with_history(record: @weblink, history_params: { team: current_team, user: current_user })

      if @weblink.persisted?
        redirect_to @weblink, notice: "Weblink was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      @weblink = Weblink.urlsafe_find!(params[:id])
      authorize! @weblink
      @weblink.assign_attributes(weblink_params)

      Weblink.update_with_history(record: @weblink, history_params: { team: current_team, user: current_user })

      if @weblink.changed? # == weblink still dirty, not saved
        render :edit, status: :unprocessable_entity
      else
        redirect_to @weblink, notice: "Weblink was successfully updated."
      end
    end

    def destroy
      @weblink = Weblink.urlsafe_find!(params[:id])
      authorize! @weblink

      Weblink.destroy_with_history(record: @weblink, history_params: { team: current_team, user: current_user })

      redirect_to weblinks_url, notice: "Weblink was successfully destroyed."
    end

    private

    def weblink_params
      params.require(:weblink).permit(:url, :name, :description)
    end
  end
end
