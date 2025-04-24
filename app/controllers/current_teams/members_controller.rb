module CurrentTeams
  class MembersController < AppCurrentTeamController
    def index
      authorize! current_user, to: :index?, with: MemberPolicy

      # members = authorized_scope(Member.all, type: :relation, as: :current_team_scope)

      @members = Member.includes(:user, :team).all
    end

    def show
      @member = Member.urlsafe_find!(params[:id])
      authorize! @member
    end

    def new
      @member = Member.new(team: current_team)
      authorize! @member
    end

    def edit
      @member = Member.urlsafe_find!(params[:id])
      authorize! @member
    end

    def create
      @member = Member.new(create_params)
      authorize! @member

      Member.create_with_history(record: @member, history_params: { team: current_team, user: current_user })

      if @member.persisted?
        redirect_to current_team_member_url(@member), notice: "Member was successfully created."
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      @member = Member.urlsafe_find!(params[:id])
      authorize! @member
      @member.assign_attributes(update_params)

      Member.update_with_history(record: @member, history_params: { team: current_team, user: current_user })

      if @member.changed? # == member still dirty, not saved
        render :edit, status: :unprocessable_content
      else
        redirect_to current_team_member_url(@member), notice: "Member was successfully updated."
      end
    end

    def destroy
      @member = Member.urlsafe_find!(params[:id])
      authorize! @member

      Member.destroy_with_history(record: @member, history_params: { team: current_team, user: current_user })

      redirect_to current_team_members_url, notice: "Member was successfully destroyed."
    end

    private

    def create_params
      params.expect(member: [:user_id, :team_id, { roles: [] }])
    end

    def update_params
      params.expect(member: [roles: []])
    end
  end
end
