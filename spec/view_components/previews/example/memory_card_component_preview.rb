# frozen_string_literal: true

module Example
  # @label Memory card
  class MemoryCardComponentPreview < ViewComponent::Preview
    PHOTO = "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='960' height='640'%3E" \
            "%3Cdefs%3E%3ClinearGradient id='g' x1='0' y1='0' x2='1' y2='1'%3E" \
            "%3Cstop offset='0' stop-color='%23edc79a'/%3E%3Cstop offset='1' stop-color='%238f3d13'/%3E" \
            "%3C/linearGradient%3E%3C/defs%3E%3Crect width='960' height='640' fill='url(%23g)'/%3E%3C/svg%3E"

    # @param visibility select [public, team, private]
    def playground(visibility: :public)
      render Example::MemoryCardComponent.new(
        memo: "We found a whole sand dollar, unbroken, right where the path meets the water. Mira spotted it first.",
        on: "4 Aug 2024", author: "Mira Kessler", team: "The Coast Year", location: "Ericeira, Portugal",
        thought: "Some days keep themselves.", tags: %w[beach walk], image: PHOTO, visibility:, href: "#"
      )
    end

    def with_image
      playground
    end

    def text_only
      render Example::MemoryCardComponent.new(
        memo: "Storm all night. The path to the beach is gone — the sea took the last three metres of it.",
        on: "18 Nov 2024", author: "Andreas Finger", team: "The Coast Year", location: "Cabo da Roca",
        tags: %w[storm winter], visibility: :team
      )
    end
  end
end
