# frozen_string_literal: true

module MarkdownHelper
  # Render a plain-Markdown string to sanitized, GFM HTML.
  # Wrap the result in `.yui-prose` at the call site for typographic styling.
  def markdown(text)
    MarkdownRenderer.render(text)
  end
end
