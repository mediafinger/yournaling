# frozen_string_literal: true

# @label Memory card
#
# Rendered with `actions: false` — Lookbook has no auth / routing context, so
# the Browse/Manage header component (policy-gated buttons, `team_memory_path`)
# can't run here. `actions: false` swaps it for a plain meta line. A
# full-fidelity preview (real header, guest user) is a TODO — see
# TODO_UI_DESIGN.md Phase 4 → "Records — component previews".
class MemoryCardComponentPreview < ViewComponent::Preview
  # @param scope select [browse, manage]
  def playground(scope: :browse)
    render MemoryCardComponent.new(memory: demo_memory, scope: scope, actions: false)
  end

  def browse
    render MemoryCardComponent.new(memory: demo_memory, scope: :browse, actions: false)
  end

  def manage
    render MemoryCardComponent.new(memory: demo_memory, scope: :manage, actions: false)
  end

  def with_attachments
    memory = demo_memory
    memory.location = FactoryBot.build_stubbed(:location, name: "Ericeira", country_code: "pt")
    render MemoryCardComponent.new(memory: memory, scope: :browse, actions: false)
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
