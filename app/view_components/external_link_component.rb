class ExternalLinkComponent < ApplicationComponent
  erb_template <<-ERB
    <span class="external_link">
      <%= @link_tag %>
    </span>
  ERB

  def initialize(url:, text:)
    @url = url
    @text = text
  end

  def before_render
    @link_tag = link_to(@text, @url, target: "_blank", rel: "noopener")
  end
end
