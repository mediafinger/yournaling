# frozen_string_literal: true

# @label Memory card
#
# Rendered with `actions: true` — the real Browse/Manage header component.
# Lookbook has no signed-in user, so the header runs in a guest context: the
# policy-gated "Rewrite" button and the visibility modal stay hidden, only the
# "Open" link shows. The demo records are `build_stubbed` so they carry ids and
# the header's path helpers (`team_memory_path`, …) resolve.
class MemoryCardComponentPreview < ViewComponent::Preview
  # @param scope select [browse, manage]
  def playground(scope: :browse)
    render MemoryCardComponent.new(memory: demo_memory, scope: scope, actions: true)
  end

  def browse
    render MemoryCardComponent.new(memory: demo_memory, scope: :browse, actions: true)
  end

  def manage
    render MemoryCardComponent.new(memory: demo_memory, scope: :manage, actions: true)
  end

  def with_attachments
    memory = demo_memory
    memory.location = FactoryBot.build_stubbed(:location, name: "Ericeira", country_code: "pt")
    render MemoryCardComponent.new(memory: memory, scope: :browse, actions: true)
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
