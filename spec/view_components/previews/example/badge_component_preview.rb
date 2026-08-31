# frozen_string_literal: true

module Example
  # @label Badge
  class BadgeComponentPreview < ViewComponent::Preview
    # @param label text
    # @param variant select [neutral, accent, success, warning, danger, info, gold]
    # @param dot toggle
    # @param icon select [~, globe, user, lock, clock, check]
    def playground(label: "Published", variant: :success, dot: false, icon: nil)
      render Example::BadgeComponent.new(label, variant:, dot:, icon: icon.presence)
    end

    def neutral
      render(Example::BadgeComponent.new("Draft"))
    end

    def success
      render(Example::BadgeComponent.new("Published", variant: :success))
    end

    def with_dot
      render(Example::BadgeComponent.new("Live", variant: :warning, dot: true))
    end

    def with_icon
      render(Example::BadgeComponent.new("Team", variant: :info, icon: "user"))
    end
  end
end
