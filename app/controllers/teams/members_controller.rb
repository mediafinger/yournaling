module Teams
  class MembersController < AppTeamsController
    def index
      @members = records_scope(Member.with_includes)

      render "teams/members/index"
    end

    def show
      @member = record(Member.with_includes, params[:id])

      render "teams/members/show"
    end
  end
end
