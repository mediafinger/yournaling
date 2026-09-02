# frozen_string_literal: true

# View helpers for the /example design-language showcase only. The records are
# built in memory (no DB, no FactoryBot — /example is reachable in production)
# and rendered with `actions: false` so no auth/policy context is needed.
module ExampleHelper
  def example_memory
    Memory.new(
      memo: "We found a whole sand dollar, unbroken, right where the path meets the water. Mira spotted it first.",
      visibility: "published",
      team: Team.new(name: "The Coast Year"),
      thought: Thought.new(text: "Some days keep themselves.", date: Date.new(2024, 8, 4)),
      weblink: Weblink.new(name: "Tide tables — Ericeira", url: "https://example.com/tides/ericeira"),
    )
  end

  def example_chronicle
    Chronicle.new(
      name: "A year on the coast",
      notice: "Twelve months of small tides on the Portuguese shore, collected walk by walk. " \
              "What started as a photo dump became the most complete record we have of a year.",
      start_date: Date.new(2024, 1, 1),
      end_date: Date.new(2024, 12, 31),
      visibility: "published",
      team: Team.new(name: "The Coast Year"),
      entries: [
        ChronicleEntry.new(entry: Thought.new(text: "First swim of the year — 8°C, brief.", date: Date.new(2024, 1, 12))),
        ChronicleEntry.new(entry: Weblink.new(name: "The lighthouse at Cabo da Roca", url: "https://example.com/cabo-da-roca")),
        ChronicleEntry.new(entry: Thought.new(text: "Storm week — the path to the beach washes out.",
          date: Date.new(2024, 11, 18))),
      ],
    )
  end
end
