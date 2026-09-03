# frozen_string_literal: true

# @label Chronicle card
#
# Rendered with `actions: true` (real Browse/Manage header) — see
# MemoryCardComponentPreview for the guest-context caveats.
class ChronicleCardComponentPreview < ViewComponent::Preview
  # @param scope select [browse, manage]
  # @param full toggle
  def playground(scope: :browse, full: true)
    render ChronicleCardComponent.new(chronicle: demo_chronicle, scope: scope, full: full, actions: true)
  end

  def collapsed
    render ChronicleCardComponent.new(chronicle: demo_chronicle, scope: :browse, full: false, actions: true)
  end

  def with_timeline
    render ChronicleCardComponent.new(chronicle: demo_chronicle(with_entries: true), scope: :browse, full: true,
      actions: true)
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

    # build_stubbed (not .new) so the record + team carry ids and the
    # Browse/Manage header can build `team_chronicle_path` etc. without a
    # "missing required keys: [:id]" route error.
    FactoryBot.build_stubbed(
      :chronicle,
      name: "A year on the coast",
      notice: "Twelve months of small tides on the Portuguese shore, collected walk by walk.",
      start_date: Date.new(2024, 1, 1), end_date: Date.new(2024, 12, 31),
      team: FactoryBot.build_stubbed(:team, name: "The Coast Year"), entries: entries
    )
  end
end
