# frozen_string_literal: true

# @label Chronicle card
#
# Rendered with `actions: false` — see MemoryCardComponentPreview for why.
class ChronicleCardComponentPreview < ViewComponent::Preview
  # @param scope select [browse, manage]
  # @param full toggle
  def playground(scope: :browse, full: true)
    render ChronicleCardComponent.new(chronicle: demo_chronicle, scope: scope, full: full, actions: false)
  end

  def collapsed
    render ChronicleCardComponent.new(chronicle: demo_chronicle, scope: :browse, full: false, actions: false)
  end

  def with_timeline
    render ChronicleCardComponent.new(chronicle: demo_chronicle(with_entries: true), scope: :browse, full: true,
      actions: false)
  end

  private

  def demo_chronicle(with_entries: false)
    entries =
      if with_entries
        [
          ChronicleEntry.new(entry: Thought.new(text: "First swim of the year — 8°C, brief.", date: Date.new(2024, 1, 12))),
          ChronicleEntry.new(entry: Weblink.new(name: "The lighthouse at Cabo da Roca", url: "https://example.com/roca")),
          ChronicleEntry.new(entry: Thought.new(text: "Storm week — the path washes out.", date: Date.new(2024, 11, 18))),
        ]
      else
        []
      end

    Chronicle.new(
      name: "A year on the coast",
      notice: "Twelve months of small tides on the Portuguese shore, collected walk by walk.",
      start_date: Date.new(2024, 1, 1), end_date: Date.new(2024, 12, 31),
      team: Team.new(name: "The Coast Year"), entries: entries
    )
  end
end
