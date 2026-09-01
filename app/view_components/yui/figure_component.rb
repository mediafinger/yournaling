# frozen_string_literal: true

module Yui
  # Framed picture with an optional italic caption and a fixed aspect ratio.
  #
  #   Yui::FigureComponent.new(src: photo_url, alt: "The northern beach at dusk",
  #                                caption: "Day 4 — the northern beach", ratio: "16/9")
  #
  # ratio: "16/9", "3/2", "4/3", "1/1" (nil = intrinsic)
  class FigureComponent < BaseComponent
    RATIOS = { "16/9" => "16-9", "3/2" => "3-2", "4/3" => "4-3", "1/1" => "1-1" }.freeze

    attr_reader :src, :alt, :caption, :ratio

    def initialize(src:, alt:, caption: nil, ratio: nil)
      super()
      @src = src
      @alt = alt.to_s
      @caption = caption.presence
      @ratio = ratio
    end

    def css_class
      ex_class("ex-figure", RATIOS[ratio] && "ex-figure--ratio-#{RATIOS[ratio]}")
    end

    slim_template <<~SLIM
      figure class=css_class
        .ex-figure__frame
          = image_tag(src, alt: alt, loading: "lazy")
        - if caption
          figcaption = caption
    SLIM
  end
end
