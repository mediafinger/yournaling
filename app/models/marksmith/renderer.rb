# frozen_string_literal: true

# Override of Marksmith's built-in renderer so the editor's live preview runs
# through the same pipeline as the published Story pages (MarkdownRenderer:
# CommonMarker GFM + SafeList sanitizer).
module Marksmith
  class Renderer
    def initialize(body:)
      @body = body
    end

    def render
      MarkdownRenderer.render(@body)
    end
  end
end
