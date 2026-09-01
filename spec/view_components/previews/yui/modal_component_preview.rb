# frozen_string_literal: true

module Yui
  # @label Modal
  class ModalComponentPreview < ViewComponent::Preview
    # @param size select [sm, md, lg]
    def playground(size: :md)
      render_with_template(locals: { size: })
    end

    def default
      render_with_template
    end
  end
end
