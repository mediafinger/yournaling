# frozen_string_literal: true

module CurrentTeams
  class MemoriesController < AppCurrentTeamController
    include MemoryFormHandling

    def index
      authorize! current_user, to: :index?, with: MemoryPolicy

      @memories = Memory.where(team: current_team)
        .includes(:team, :picture, :location, :thought, :weblink)
        .order(created_at: :desc)
    end

    def show
      @memory = Memory.urlsafe_find!(params[:id])
      authorize! @memory
    end

    def new
      @memory = Memory.new(team: current_team, visibility: "internal")
      authorize! @memory
    end

    def edit
      @memory = Memory.urlsafe_find!(params[:id])
      authorize! @memory
    end

    def create
      attrs = memory_params
      insight_attrs = MemoryInsightAttacher.extract_insight_params!(attrs)

      @memory = Memory.new(attrs.compact_blank.merge(team: current_team))
      authorize! @memory

      ActiveRecord::Base.transaction do
        create_with_event(record: @memory)
        MemoryInsightAttacher.call(memory: @memory, params: insight_attrs, user: current_user) if @memory.persisted?
      end

      if @memory.persisted?
        redirect_to current_team_memory_url(@memory.urlsafe_id), notice: "Memory was successfully created."
      else
        render :new, status: :unprocessable_content
      end
    rescue ActiveRecord::RecordInvalid
      render :new, status: :unprocessable_content
    end

    def update
      attrs = memory_params
      insight_attrs = MemoryInsightAttacher.extract_insight_params!(attrs)

      @memory = Memory.urlsafe_find!(params[:id])
      authorize! @memory
      @memory.assign_attributes(attrs.compact_blank)

      ActiveRecord::Base.transaction do
        update_with_event(record: @memory)
        MemoryInsightAttacher.call(memory: @memory, params: insight_attrs, user: current_user) unless @memory.changed?
      end

      if @memory.changed? # == memory still dirty, not saved
        render :edit, status: :unprocessable_content
      else
        redirect_to current_team_memory_url(@memory.urlsafe_id), notice: "Memory was successfully updated."
      end
    rescue ActiveRecord::RecordInvalid
      render :edit, status: :unprocessable_content
    end

    def destroy
      @memory = Memory.urlsafe_find!(params[:id])
      authorize! @memory

      destroy_with_event(record: @memory)

      redirect_to current_team_memories_url, notice: "Memory was successfully destroyed."
    end

    private

    def memory_params
      permit_memory_params
    end
  end
end
