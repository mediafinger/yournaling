# frozen_string_literal: true

class PagesController < ApplicationController
  skip_before_action :authenticate, only: %i[show check_newer newer]
  skip_verify_authorized only: %i[show check_newer newer]

  def show
    @pagy, @publishings = pagy(
      :offset,
      Publishing.published.reorder(republished_at: :desc).includes(:team, post: %i[team])
    )
    # @newest_at is the feed cursor: the timestamp the `feed-refresh` controller
    # polls `check_newer` with. Named the same in both feed controllers (here it
    # tracks `republished_at`, in CurrentTeams::PagesController `updated_at`).
    @newest_at = @publishings.first&.republished_at&.iso8601(6) || Time.current.iso8601(6)
  end

  def check_newer
    since_time = parse_since_param
    newer_scope = Publishing.published.where("republished_at > ?", since_time).reorder(republished_at: :desc)

    render json: {
      count: newer_scope.count,
      latest_at: newer_scope.first&.republished_at&.iso8601(6),
    }
  end

  def newer
    since_time = parse_since_param
    @publishings = Publishing.published.where("republished_at > ?", since_time).reorder(republished_at: :desc).includes(
      :team, post: %i[team]
    )
    @newest_at = @publishings.first&.republished_at&.iso8601(6) || params[:since]

    render layout: false
  end

  private

  def parse_since_param
    params[:since].present? ? Time.zone.parse(params[:since]) : Time.current
  end
end
