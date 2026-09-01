# frozen_string_literal: true

module Yui
  # A disclosure menu — a native <details> so it works without JS; the
  # `yui-menu` controller adds outside-click / Escape close and aria wiring.
  #
  #   = render(Yui::MenuComponent.new("+ New", align: :end, trigger_class: "ex-nav-item ex-nav-item--strong")) do
  #     = render(Yui::MenuItemComponent.new("Memory", href: new_memory_path))
  #     = render(Yui::MenuItemComponent.new("Chronicle", href: new_chronicle_path))
  #
  # align:         :start (default) or :end (panel right-aligned under the trigger)
  # trigger_class: extra classes for the <summary> (the caller styles it)
  class MenuComponent < BaseComponent
    ALIGNS = %i[start end].freeze

    renders_one :trigger

    def initialize(label = nil, align: :start, trigger_class: nil, label_id: nil)
      super()
      @label = label
      @align = ex_token(align, allowed: ALIGNS, default: :start)
      @trigger_class = trigger_class
      @label_id = label_id
    end

    attr_reader :label, :align, :label_id

    def summary_class
      ex_class("ex-menu__trigger", @trigger_class)
    end
  end
end
