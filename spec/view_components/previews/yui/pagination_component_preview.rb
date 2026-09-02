# frozen_string_literal: true

module Yui
  # @label Pagination
  class PaginationComponentPreview < ViewComponent::Preview
    # @param count number
    # @param page number
    # @param limit number
    def playground(count: 235, page: 5, limit: 20)
      render Yui::PaginationComponent.new(pagy: fake_pagy(count:, page:, limit:), url: url_proc)
    end

    def first_page
      render Yui::PaginationComponent.new(pagy: fake_pagy(count: 235, page: 1, limit: 20), url: url_proc)
    end

    def middle
      render Yui::PaginationComponent.new(pagy: fake_pagy(count: 235, page: 6, limit: 20), url: url_proc)
    end

    def last_page
      render Yui::PaginationComponent.new(pagy: fake_pagy(count: 235, page: 12, limit: 20), url: url_proc)
    end

    def few_pages
      render Yui::PaginationComponent.new(pagy: fake_pagy(count: 45, page: 2, limit: 20), url: url_proc)
    end

    private

    def fake_pagy(count:, page:, limit:)
      Pagy::Offset.new(count:, page:, limit:)
    end

    def url_proc
      ->(page) { "?page=#{page}" }
    end
  end
end
