# frozen_string_literal: true

module Yui
  # Display headline, levels 1–4, with an optional eyebrow and alignment.
  #
  #   Yui::HeadlineComponent.new("A year in the mountains", level: 1, eyebrow: "Chronicle")
  #   = render(Yui::HeadlineComponent.new(level: 2)) { "Everything we kept" }
  #
  # `level:` also drives the semantic tag (h1…h4). Pass `display: true` on a
  # level-1 headline for the oversized hero treatment.
  class HeadlineComponent < BaseComponent
    LEVELS = [1, 2, 3, 4].freeze
    ALIGNMENTS = %i[left center].freeze

    attr_reader :level, :eyebrow, :align, :display

    def initialize(text = nil, level: 2, eyebrow: nil, align: :left, display: false)
      super()
      @text = text
      @level = LEVELS.include?(level.to_i) ? level.to_i : 2
      @eyebrow = eyebrow.presence
      @align = ex_token(align, allowed: ALIGNMENTS, default: :left)
      @display = display
    end

    def text
      @text || content
    end

    def tag_name
      "h#{level}"
    end

    def css_class
      ex_class(
        display ? "ex-display" : "ex-h#{level}",
        align == :center && "ex-align-center",
      )
    end

    slim_template <<~SLIM
      div class=("ex-align-center" if align == :center)
        - if eyebrow
          p.ex-eyebrow = eyebrow
        = content_tag(tag_name, text, class: css_class)
    SLIM
  end
end
