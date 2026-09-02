# frozen_string_literal: true

module Yui
  # One item in a Yui::Menu panel. A link by default; pass `as: :button` for a
  # non-navigating action (e.g. a form submit / JS action).
  class MenuItemComponent < BaseComponent
    def initialize(label = nil, href: nil, as: :link, variant: :default, active: false, data: {}, method: nil)
      super()
      @label = label
      @href = href
      @as = as.to_sym
      @variant = variant.to_sym
      @active = active
      @data = data
      @method = method
    end

    def call
      klass = yui_class("yui-menu__item", @variant == :danger && "yui-menu__item--danger",
        @active && "yui-menu__item--active")
      aria = { current: (@active ? "page" : nil) }
      if @as == :button || @href.nil?
        tag.button(@label || content, type: "button", role: "menuitem", class: klass, aria:, data: @data)
      else
        link_to(@label || content, @href, role: "menuitem", class: klass, aria:, data: @data.merge(turbo_method_data))
      end
    end

    private

    def turbo_method_data
      @method ? { turbo_method: @method } : {}
    end
  end
end
