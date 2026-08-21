# frozen_string_literal: true

class EmptyStateComponent < ApplicationComponent
  attr_reader :icon, :title, :description, :cta_label, :cta_path

  def initialize(title:, icon: "📖", description: nil, cta_label: nil, cta_path: nil)
    super()
    @icon = icon
    @title = title
    @description = description
    @cta_label = cta_label
    @cta_path = cta_path
  end
end
