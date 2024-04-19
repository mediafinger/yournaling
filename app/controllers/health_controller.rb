# NOTE: this controller takes inspiration from Rails::HealthController defined in the Rails code base
# but inherits from our ApplicationController, to ensure the normal includes do not break our app
# and it makes one DB request to ensure the DB is up and running
# https://github.com/rails/rails/blob/main/railties/lib/rails/health_controller.rb
#
# rubocop:disable Rails/HttpStatus
class HealthController < ApplicationController
  rescue_from(Exception) { render_down }

  skip_before_action :authenticate, only: %i[show]
  skip_verify_authorized only: %i[show]

  def show
    render_up
  end

  private

  def render_up
    User.first!

    render html: html_status(color: "green", status: 200), status: 200
  end

  def render_down
    render html: html_status(color: "red", status: 503), status: 503 # Rails 7.1 uses 500
  end

  # rubocop:disable Rails/OutputSafety
  def html_status(color:, status:)
    %(<!DOCTYPE html><html><body style="background-color: #{color}; color: white"><h1>#{status}</h1></body></html>).html_safe
  end
  # rubocop:enable Rails/OutputSafety
end
# rubocop:enable Rails/HttpStatus
