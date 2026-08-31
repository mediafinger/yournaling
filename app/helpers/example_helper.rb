# frozen_string_literal: true

# View helpers for the /example design-language showcase only.
module ExampleHelper
  # Sample data for the composed Memory / Chronicle record cards.
  def record_examples(photo:, cover:)
    {
      sand_dollar: {
        memo: "We found a whole sand dollar, unbroken, right where the path meets the water. Mira spotted it first.",
        on: "4 Aug 2024", author: "Mira Kessler", team: "The Coast Year",
        location: "Ericeira, Portugal", thought: "Some days keep themselves.",
        tags: %w[beach walk], image: photo, visibility: :public, href: "#records"
      },
      storm_night: {
        memo: "Storm all night. The path to the beach is gone — the sea took the last three metres of it.",
        on: "18 Nov 2024", author: "Andreas Finger", team: "The Coast Year",
        location: "Cabo da Roca", tags: %w[storm winter], visibility: :team
      },
      coast_year: {
        title: "A year on the coast", start_date: "Jan 2024", end_date: "Dec 2024",
        author: "Andreas Finger", team: "The Coast Year", memory_count: 48,
        visibility: :team, cover: cover, href: "#records",
        summary: "Twelve months of small tides on the Portuguese shore, collected walk by walk. " \
                 "What started as a photo dump became the most complete record we have of a year.",
        entries: [
          { title: "First swim of the year — 8°C, brief", date: "12 Jan" },
          { title: "The lighthouse at Cabo da Roca", date: "3 Mar" },
          { title: "Sand dollar, unbroken", date: "4 Aug" },
          { title: "Storm week — the path washes out", date: "18 Nov" },
        ]
      },
    }
  end
end
