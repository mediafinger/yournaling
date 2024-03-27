class PagesController < ApplicationController
  skip_before_action :authenticate, only: %i[home error]
  skip_verify_authorized only: %i[home error]

  # TODO: add index action with (memories) stream
  #
  # TODO: add welcome message, suggest to join team or to create a (single) team to create content
  #
  def home
  end

  def error
  end
end
