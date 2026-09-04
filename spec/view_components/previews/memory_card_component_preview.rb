# frozen_string_literal: true

# @label Memory card
#
# Memory has no header — no name, and it always shows the whole memo, so
# there's nothing to open. Lookbook has no signed-in user, so the footer runs
# in a guest context: Rewrite and the visibility control stay hidden, only the
# date and team/creator show. The demo records are `build_stubbed` so they
# carry ids and the footer's path helpers (`team_home_path`, …) resolve.
class MemoryCardComponentPreview < ViewComponent::Preview
  # @param scope select [browse, manage]
  def playground(scope: :browse)
    render MemoryCardComponent.new(memory: demo_memory, scope: scope)
  end

  def browse
    render MemoryCardComponent.new(memory: demo_memory, scope: :browse)
  end

  def manage
    render MemoryCardComponent.new(memory: demo_memory, scope: :manage)
  end

  def with_attachments
    memory = demo_memory
    memory.location = FactoryBot.build_stubbed(:location, name: "Ericeira", country_code: "pt")
    render MemoryCardComponent.new(memory: memory, scope: :browse)
  end

  private

  def demo_memory
    FactoryBot.build_stubbed(
      :memory, weblink: nil,
      memo: "We found a whole sand dollar, unbroken, right where the path meets the water.",
      team: FactoryBot.build_stubbed(:team, name: "The Coast Year")
    )
  end
end
