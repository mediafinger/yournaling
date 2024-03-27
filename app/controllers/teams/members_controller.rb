module Teams
  class MembersController < AppTeamsController
    def index
      @members = records_scope(Member.with_includes)
    end

    def show
      @member = record(Member.with_includes, params[:id])
    end
  end
end
