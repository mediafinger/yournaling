# frozen_string_literal: true

# A text link to an external site (new tab, rel=noopener, trailing ↗).
class ExternalLinkComponent < ApplicationComponent
  attr_reader :url, :text

  def initialize(url:, text:)
    @url = url
    @text = text
  end
end
