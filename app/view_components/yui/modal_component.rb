# frozen_string_literal: true

module Yui
  # A modal dialog built on native <dialog> (Escape + focus trap for free).
  # The `yui-modal` controller wires the trigger, backdrop-click and close.
  #
  #   = render(Yui::ModalComponent.new(title: "Change visibility")) do |modal|
  #     - modal.with_trigger do
  #       = render Yui::ButtonComponent.new("Edit", variant: :ghost, size: :sm)
  #     p Body content…
  #     - modal.with_footer do
  #       = render Yui::ButtonComponent.new("Save", type: "submit")
  #
  # size: :sm, :md (default), :lg
  class ModalComponent < BaseComponent
    SIZES = %i[sm md lg].freeze

    renders_one :trigger
    renders_one :footer

    def initialize(title: nil, size: :md, dismissible: true)
      super()
      @title = title
      @size = ex_token(size, allowed: SIZES, default: :md)
      @dismissible = dismissible
    end

    attr_reader :title, :size, :dismissible

    def title_id
      @title_id ||= "ex-modal-#{SecureRandom.hex(4)}"
    end

    def dialog_class
      ex_class("ex-modal", size != :md && "ex-modal--#{size}")
    end
  end
end
