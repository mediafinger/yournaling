# frozen_string_literal: true

module Example
  # A Chronicle rendered as a card: cover, title, summary, a short vertical
  # timeline of its entries, and a footer with authorship and a call to action.
  #
  #   Example::ChronicleCardComponent.new(
  #     title: "A year on the coast",
  #     summary: "Twelve months of small tides, collected walk by walk.",
  #     start_date: "Jan 2024", end_date: "Dec 2024",
  #     author: "Andreas Finger", team: "The Coast Year",
  #     memory_count: 48, visibility: :team,
  #     entries: [
  #       { title: "First swim of the year", date: "12 Jan" },
  #       { title: "The lighthouse at Cabo da Roca", date: "3 Mar" },
  #       { title: "Storm week", date: "18 Nov" },
  #     ],
  #     href: "#",
  #   )
  class ChronicleCardComponent < BaseComponent
    VISIBILITIES = MemoryCardComponent::VISIBILITIES

    attr_reader :title, :summary, :start_date, :end_date, :author, :team,
      :memory_count, :entries, :cover, :visibility, :href

    def initialize(
      title:, summary:, start_date:, author:, team:, end_date: nil,
      memory_count: 0, entries: [], cover: nil, visibility: :team, href: nil
    )
      super()
      @title = title
      @summary = summary
      @start_date = start_date
      @end_date = end_date.presence
      @author = author
      @team = team
      @memory_count = memory_count
      @entries = Array(entries)
      @cover = cover.presence
      @visibility = VISIBILITIES.fetch(visibility.to_sym, VISIBILITIES[:team])
      @href = href.presence
    end

    def date_range
      end_date ? "#{start_date} – #{end_date}" : "Since #{start_date}"
    end
  end
end
