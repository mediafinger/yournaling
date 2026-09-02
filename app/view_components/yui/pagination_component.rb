# frozen_string_literal: true

module Yui
  # A classic numbered pager for a Pagy result. Presentational: it reads page
  # numbers off the `pagy` object and builds hrefs with `url` (defaults to
  # `pagy.page_url`, which keeps the current query string).
  #
  #   = render Yui::PaginationComponent.new(pagy: @pagy)
  #   = render Yui::PaginationComponent.new(pagy: @pagy, url: ->(page) { admin_users_path(page:) })
  #
  # Renders nothing when there is only one page.
  class PaginationComponent < BaseComponent
    DEFAULT_SLOTS = 7

    def initialize(pagy:, url: nil, slots: DEFAULT_SLOTS, label: "Pagination")
      super()
      @pagy = pagy
      @url = url || pagy.method(:page_url)
      @slots = [slots.to_i, 3].max
      @label = label
    end

    attr_reader :pagy, :label

    def render? = pagy.pages > 1

    def current_page = pagy.page

    def page_url(page) = @url.call(page)

    # [1, :gap, 7, 8, 9, :gap, 42] — a windowed page series around the current page.
    def series
      last = pagy.pages
      return (1..last).to_a if @slots >= last

      half = (@slots - 1) / 2
      start = if pagy.page <= half
                1
              elsif pagy.page > last - @slots + half
                last - @slots + 1
              else
                pagy.page - half
              end

      pages = (start...(start + @slots)).to_a
      if @slots >= DEFAULT_SLOTS
        pages[0] = 1
        pages[1] = :gap unless pages[1] == 2
        pages[-2] = :gap unless pages[-2] == last - 1
        pages[-1] = last
      end
      pages
    end

    def prev_page = pagy.previous
    def next_page = pagy.next
  end
end
