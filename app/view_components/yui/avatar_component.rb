# frozen_string_literal: true

module Yui
  # Round avatar. Shows the image when `src:` is given, otherwise falls back to
  # the initials derived from `name:`.
  #
  #   Yui::AvatarComponent.new(name: "Andreas Finger")
  #   Yui::AvatarComponent.new(name: "Mira Kessler", src: "/uploads/mira.jpg", size: :lg)
  #
  # size: :sm, :md (default), :lg, :xl
  class AvatarComponent < BaseComponent
    SIZES = %i[sm md lg xl].freeze

    attr_reader :name, :src, :size

    def initialize(name:, src: nil, size: :md)
      super()
      @name = name.to_s
      @src = src.presence
      @size = ex_token(size, allowed: SIZES, default: :md)
    end

    def initials
      parts = name.split(/\s+/).reject(&:empty?)
      return "?" if parts.empty?

      (parts.first[0].to_s + (parts.length > 1 ? parts.last[0].to_s : "")).upcase
    end

    def css_class
      ex_class("ex-avatar", size != :md && "ex-avatar--#{size}")
    end
  end
end
