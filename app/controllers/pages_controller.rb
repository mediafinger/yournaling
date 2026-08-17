# frozen_string_literal: true

class PagesController < ApplicationController
  skip_before_action :authenticate, only: %i[show]
  skip_verify_authorized only: %i[show]

  def show
    @pagy, @publishings = pagy(
      :offset,
      Publishing.published.reorder(republished_at: :desc).includes(:team, post: %i[team])
    )
  end
end
