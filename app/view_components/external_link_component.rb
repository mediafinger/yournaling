class ExternalLinkComponent < ApplicationComponent
  slim_template <<~SLIM
    span class="external_link"
      = @link_tag
  SLIM

  def initialize(url:, text:)
    @url = url
    @text = text
  end

  def before_render
    @link_tag = link_to(@text, @url, target: "_blank", rel: "noopener")
  end
end
