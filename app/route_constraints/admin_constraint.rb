# NOTE: used in config/routes.rb to ensure only Admins can access certain areas
#
class AdminConstraint
  class << self
    def matches?(request)
      return false unless request.session[:user_id]

      user = User.urlsafe_find(request.session[:user_id])
      return false unless user.present?

      user.admin?
    end
  end
end
