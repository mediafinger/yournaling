# frozen_string_literal: true

module Yui
  # @label Prose
  class ProseComponentPreview < ViewComponent::Preview
    def default
      render(Yui::ProseComponent.new) do
        <<~HTML.html_safe
          <p>A <strong>Memory</strong> is the smallest unit here — a note, a photo, a place.
          Group them into an <em>Experience</em>, and a run of experiences becomes a
          <a href="#">Chronicle</a>.</p>
          <ul><li>Write first, organise later.</li><li>Every record can be private, team-only, or public.</li></ul>
        HTML
      end
    end
  end
end
