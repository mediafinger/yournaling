# frozen_string_literal: true

module Yui
  # An ARIA tab set. Each panel slot carries its own tab label; the
  # `yui-tabs` controller toggles `aria-selected` / `hidden` and supports
  # arrow-key navigation.
  #
  #   = render(Yui::TabsComponent.new(label: "Location")) do |tabs|
  #     - tabs.with_panel(title: "Address") do
  #       = render Yui::FieldComponent.new(...)
  #     - tabs.with_panel(title: "GPS") do
  #       …
  class TabsComponent < BaseComponent
    renders_many :panels, "PanelComponent"

    def initialize(label: "Tabs", active: 0)
      super()
      @label = label
      @active = active.to_i
    end

    attr_reader :label, :active

    def uid
      @uid ||= "ex-tabs-#{SecureRandom.hex(4)}"
    end

    # A single tab + its panel. `title` is the clickable tab label.
    class PanelComponent < BaseComponent
      attr_reader :title

      def initialize(title:)
        super()
        @title = title
      end

      def call
        content
      end
    end
  end
end
