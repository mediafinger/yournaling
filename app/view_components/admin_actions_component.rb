# frozen_string_literal: true

class AdminActionsComponent < ApplicationComponent
  def initialize(record:, name:)
    @record = record
    @name = name
  end

  attr_reader :name

  def show?
    helpers.action_name != "show"
  end

  def show_path
    send(:"admin_#{name}_path", @record)
  end

  def edit_path
    send(:"edit_admin_#{name}_path", @record)
  end

  def events_path
    admin_record_events_path(record_id: @record.to_param)
  end
end
