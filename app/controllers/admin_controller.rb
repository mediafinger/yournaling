# frozen_string_literal: true

class AdminController < ApplicationController
  skip_verify_authorized

  before_action :authenticate_admin!

  layout "admin_area"
end
