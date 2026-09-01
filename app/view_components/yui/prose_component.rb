# frozen_string_literal: true

module Yui
  # Wraps a block of rich HTML content (headings, paragraphs, lists, links,
  # <em>/<strong>, inline code) and gives it coherent editorial typography.
  #
  #   = render(Yui::ProseComponent.new) do
  #     p We kept a shell from the northern beach...
  class ProseComponent < BaseComponent
    slim_template <<~SLIM
      .ex-prose
        = content
    SLIM
  end
end
