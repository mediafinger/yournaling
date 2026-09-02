# frozen_string_literal: true

class AdminShowMetaInformationComponent < ApplicationComponent
  def initialize(record:)
    @record = record
  end

  attr_reader :record
end
