# frozen_string_literal: true

# @label Empty state
class EmptyStateComponentPreview < ViewComponent::Preview
  # @param icon text
  # @param title text
  # @param description text
  # @param cta_label text
  def playground(
    icon: "📖",
    title: "No published stories or memories yet",
    description: "Explore the public journals and travel memories shared by teams around the world.",
    cta_label: nil
  )
    render EmptyStateComponent.new(
      icon:, title:, description: description.presence,
      cta_label: cta_label.presence, cta_path: cta_label.presence && "#"
    )
  end

  def bare
    render EmptyStateComponent.new(title: "Nothing here yet")
  end

  def with_cta
    render EmptyStateComponent.new(
      icon: "🧭", title: "No chronicles yet",
      description: "Start one to collect memories along a route or a theme.",
      cta_label: "New chronicle", cta_path: "#"
    )
  end
end
