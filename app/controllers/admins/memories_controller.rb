# frozen_string_literal: true

module Admins
  class MemoriesController < AdminController
    include MemoryFormHandling

    def index
      @pagy, @memories = pagy(
        :offset, Memory.includes(:team, :picture, :location, :thought, :weblink).order(created_at: :desc)
      )
    end

    def show
      @memory = Memory.includes(:team, :picture, :location, :thought, :weblink).urlsafe_find!(params[:id])
    end

    def new
      @memory = Memory.new(team: nil, visibility: "draft")
    end

    def edit
      @memory = Memory.urlsafe_find!(params[:id])
    end

    def create
      @memory = Memory.new(memory_params)

      ActiveRecord::Base.transaction do
        Memory.create_with_event(
          record: @memory, event_params: { team: nil, user: current_user, done_by_admin: true }
        )

        MemoryInsightAttacher.call(memory: @memory, params: memory_params, user: current_user) if @memory.persisted?
      end

      if @memory.persisted?
        redirect_to admin_memory_url(@memory), notice: "Memory was successfully created."
      else
        render :new, status: :unprocessable_content
      end
    rescue ActiveRecord::RecordInvalid
      render :new, status: :unprocessable_content
    end

    def update
      @memory = Memory.urlsafe_find!(params[:id])
      @memory.assign_attributes(memory_params)

      ActiveRecord::Base.transaction do
        Memory.update_with_event(
          record: @memory, event_params: { team: nil, user: current_user, done_by_admin: true }
        )

        # @memory.changed? == memory still dirty, not saved
        MemoryInsightAttacher.call(memory: @memory, params: memory_params, user: current_user) unless @memory.changed?
      end

      if @memory.changed? # == memory still dirty, not saved
        render :edit, status: :unprocessable_content
      else
        redirect_to admin_memory_url(@memory), notice: "Memory was successfully updated."
      end
    rescue ActiveRecord::RecordInvalid
      render :edit, status: :unprocessable_content
    end

    def destroy
      @memory = Memory.urlsafe_find!(params[:id])

      Memory.destroy_with_event(
        record: @memory, event_params: { team: nil, user: current_user, done_by_admin: true }
      )

      # TODO: destroy orphaned insights?

      redirect_to admin_memories_url, notice: "Memory was successfully destroyed."
    end

    private

    def memory_params
      permit_memory_params(additional_keys: [:team_id])
    end
  end
end
