# frozen_string_literal: true

module Example
  # @label Figure
  class FigureComponentPreview < ViewComponent::Preview
    PHOTO = "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='960' height='640'%3E" \
            "%3Cdefs%3E%3ClinearGradient id='g' x1='0' y1='0' x2='1' y2='1'%3E" \
            "%3Cstop offset='0' stop-color='%23edc79a'/%3E%3Cstop offset='.55' stop-color='%23c9793c'/%3E" \
            "%3Cstop offset='1' stop-color='%238f3d13'/%3E%3C/linearGradient%3E%3C/defs%3E" \
            "%3Crect width='960' height='640' fill='url(%23g)'/%3E%3C/svg%3E"

    # @param caption text
    # @param ratio select ["16/9", "3/2", "4/3", "1/1"]
    def playground(caption: "Day 4 — the northern beach", ratio: "3/2")
      render Example::FigureComponent.new(src: PHOTO, alt: "The northern beach at dusk", caption: caption.presence, ratio:)
    end

    def with_caption
      render(Example::FigureComponent.new(src: PHOTO, alt: "The northern beach", caption: "Day 4 — the northern beach",
        ratio: "3/2"))
    end

    def square
      render(Example::FigureComponent.new(src: PHOTO, alt: "", ratio: "1/1"))
    end
  end
end
