# frozen_string_literal: true

module Yui
  # @label Chronicle card
  class ChronicleCardComponentPreview < ViewComponent::Preview
    COVER = "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='1200' height='420'%3E" \
            "%3Cdefs%3E%3ClinearGradient id='c' x1='0' y1='0' x2='1' y2='1'%3E" \
            "%3Cstop offset='0' stop-color='%23b5541e'/%3E%3Cstop offset='1' stop-color='%232a2520'/%3E" \
            "%3C/linearGradient%3E%3C/defs%3E%3Crect width='1200' height='420' fill='url(%23c)'/%3E%3C/svg%3E"

    ENTRIES = [
      { title: "First swim of the year — 8°C, brief", date: "12 Jan" },
      { title: "The lighthouse at Cabo da Roca", date: "3 Mar" },
      { title: "Sand dollar, unbroken", date: "4 Aug" },
      { title: "Storm week — the path washes out", date: "18 Nov" },
    ].freeze

    # @param visibility select [team, public, private]
    # @param with_cover toggle
    def playground(visibility: :team, with_cover: true)
      render Yui::ChronicleCardComponent.new(
        title: "A year on the coast",
        summary: "Twelve months of small tides on the Portuguese shore, collected walk by walk.",
        start_date: "Jan 2024", end_date: "Dec 2024", author: "Andreas Finger", team: "The Coast Year",
        memory_count: 48, visibility:, cover: (COVER if with_cover), href: "#", entries: ENTRIES
      )
    end

    def without_cover
      playground(with_cover: false)
    end
  end
end
