# frozen_string_literal: true

# Renders a plain-Markdown string (GitHub Flavored Markdown) to sanitized HTML.
#
# This is the single renderer for both the Marksmith editor preview
# (see app/models/marksmith/renderer.rb) and the Story show pages, so what an
# author previews is exactly what a reader gets.
#
# Raw HTML in the source is dropped (`unsafe: false`) and the result is passed
# through a SafeList sanitizer as defense in depth.
class MarkdownRenderer
  RENDER_OPTIONS = {
    render: { unsafe: false, hardbreaks: false },
    extension: {
      table: true,
      strikethrough: true,
      tasklist: true,
      autolink: true,
      tagfilter: true,
      header_ids: nil,
    },
  }.freeze

  ALLOWED_TAGS = (
    Rails::HTML5::SafeListSanitizer.allowed_tags.to_a +
    %w[table thead tbody tfoot tr th td input]
  ).to_set.freeze

  ALLOWED_ATTRIBUTES = (
    Rails::HTML5::SafeListSanitizer.allowed_attributes.to_a +
    %w[class type checked disabled colspan rowspan align start]
  ).to_set.freeze

  class << self
    # @param markdown [String, nil]
    # @return [ActiveSupport::SafeBuffer]
    def render(markdown)
      return "".html_safe if markdown.blank?

      html = Commonmarker.to_html(markdown.to_s.dup.force_encoding("UTF-8"), options: RENDER_OPTIONS)

      # Safe by construction: CommonMarker ran with `unsafe: false` (no raw HTML)
      # and the result is filtered through a SafeList sanitizer just above.
      sanitizer.sanitize(html, tags: ALLOWED_TAGS, attributes: ALLOWED_ATTRIBUTES).html_safe # rubocop:disable Rails/OutputSafety
    end

    private

    def sanitizer
      @sanitizer ||= Rails::HTML5::SafeListSanitizer.new
    end
  end
end
