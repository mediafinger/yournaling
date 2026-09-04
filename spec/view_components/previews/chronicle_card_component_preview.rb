# frozen_string_literal: true

# @label Chronicle card
#
# Lookbook has no signed-in user, so the header/footer run in a guest
# context: Rewrite and the visibility control stay hidden, the title still
# links to the show page. The demo records are `build_stubbed` so they carry
# ids and the path helpers (`team_chronicle_path`, …) resolve.
class ChronicleCardComponentPreview < ViewComponent::Preview
  # @param scope select [browse, manage]
  # @param full toggle
  def playground(scope: :browse, full: true)
    render ChronicleCardComponent.new(chronicle: demo_chronicle, scope: scope, full: full)
  end

  def collapsed
    render ChronicleCardComponent.new(chronicle: demo_chronicle, scope: :browse, full: false)
  end

  def with_timeline
    render ChronicleCardComponent.new(chronicle: demo_chronicle(with_entries: true), scope: :browse, full: true)
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
