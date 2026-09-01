# frozen_string_literal: true

module Yui
  # @label Badge
  class BadgeComponentPreview < ViewComponent::Preview
    # @param label text
    # @param variant select [neutral, accent, success, warning, danger, info, gold]
    # @param dot toggle
    # @param icon select [~, globe, user, lock, clock, check]
    def playground(label: "Published", variant: :success, dot: false, icon: nil)
      render Yui::BadgeComponent.new(label, variant:, dot:, icon: icon.presence)
    end

    def neutral
      render(Yui::BadgeComponent.new("Draft"))
    end

    def success
      render(Yui::BadgeComponent.new("Published", variant: :success))
    end

    def with_dot
      render(Yui::BadgeComponent.new("Live", variant: :warning, dot: true))
    end

    def with_icon
      render(Yui::BadgeComponent.new("Team", variant: :info, icon: "user"))
    end
  end
end
