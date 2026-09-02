# frozen_string_literal: true

module Yui
  # @label Menu item
  #
  # One row inside a `Yui::Menu` panel — see the Menu preview for the whole
  # disclosure. A link by default; `as: :button` for a non-navigating action.
  class MenuItemComponentPreview < ViewComponent::Preview
    # @param label text
    # @param variant select [default, danger]
    # @param active toggle
    # @param as select [link, button]
    def playground(label: "Edit memory", variant: :default, active: false, as: :link)
      render Yui::MenuItemComponent.new(label, href: (as.to_sym == :link ? "#" : nil), as:, variant:, active:)
    end

    def link
      render Yui::MenuItemComponent.new("Open in browse", href: "#")
    end

    def button
      render Yui::MenuItemComponent.new("Duplicate", as: :button)
    end

    def danger
      render Yui::MenuItemComponent.new("Delete", as: :button, variant: :danger)
    end

    def active
      render Yui::MenuItemComponent.new("Current page", href: "#", active: true)
    end
  end
end
