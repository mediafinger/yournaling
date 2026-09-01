# frozen_string_literal: true

module Yui
  # A Memory rendered as a card, composed entirely from design-language
  # primitives (Card, Badge, Avatar, Tag, Icon, Blockquote).
  #
  #   Yui::MemoryCardComponent.new(
  #     memo: "We found a whole sand dollar, unbroken, right where the path meets the water.",
  #     on: "4 August 2024",
  #     author: "Mira Kessler",
  #     team: "The Coast Year",
  #     location: "Ericeira, Portugal",
  #     thought: "Some days keep themselves.",
  #     tags: ["beach", "walk"],
  #     visibility: :public,
  #   )
  class MemoryCardComponent < BaseComponent
    VISIBILITIES = {
      public: { label: "Public", variant: :success, icon: "globe" },
      team: { label: "Team", variant: :info, icon: "user" },
      private: { label: "Private", variant: :neutral, icon: "lock" },
    }.freeze

    attr_reader :memo, :on, :author, :team, :location, :thought, :tags, :image, :visibility, :href

    def initialize(
      memo:, on:, author:, team:, location: nil, thought: nil, tags: [],
      image: nil, visibility: :public, href: nil
    )
      super()
      @memo = memo
      @on = on
      @author = author
      @team = team
      @location = location.presence
      @thought = thought.presence
      @tags = Array(tags)
      @image = image.presence
      @visibility = VISIBILITIES.fetch(visibility.to_sym, VISIBILITIES[:public])
      @href = href.presence
    end
  end
end
