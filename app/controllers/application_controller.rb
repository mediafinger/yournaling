class ApplicationController < ActionController::Base
  protect_from_forgery prepend: true

  include RequestContext # sets the Current.objects

  # Detailed error pages must only be used in development! By default use our custom (less informative) error pages
  include ErrorHandler unless AppConf.is?(:debug, true) && !AppConf.production_env

  before_action :ensure_html_safe_flash
  before_action :authenticate

  def authenticate(allow_guest: true)
    return if current_user.present? && (current_user.persisted? || allow_guest)

    session[:return_to] ||= request.referer
    redirect_to :login
  end

  def current_user
    @current_user ||= session[:user_yid] ? User.urlsafe_find(session[:user_yid]) : User.new(name: "Guest")
  end
  helper_method :current_user

  def current_team
    Current.team
  end
  helper_method :current_team

  def current_member
    Current.member
  end
  helper_method :current_member

  # dry-validates the dry-contract against the given params
  # which can be either a hash or an ActionController::Parameters object
  #
  def validate_params!(contract, parameters)
    p = parameters.is_a?(ActionController::Parameters) ? parameters.to_unsafe_h : parameters

    ContractValidation.validate!(contract, p)
  end

  # dry-validates the dry-contract implictly against the content of the params' :data key
  # which are expected to adhere to the JSON:API standard https://jsonapi.org/format/#crud-creating
  # ensure the :type is present and matches the given type (throws 400 if not)
  #
  def validate_params_for!(contract, type)
    raise ParamsTypeError.new(key: :type, got: data_params[:type], expected: type) if data_params[:type].to_s != type.to_s

    ContractValidation.validate!(contract, data_params[:attributes])
  end

  # we let Rails / ActionController::StrongParameters ensure that
  # the json request body includes a :data key (and that it is not empty)
  #
  def data_params
    params.require(:data).to_unsafe_h # contains :type and attributes: {...}
  end

  # throwing the error here, after catching it in our routes,
  # means our normal error handler process will be used
  # to log the error and display a message to the user
  def error_404
    raise ActionController::RoutingError.new("Path #{request.path} could not be found")
  end

  private

  # allow to create multiple flashes of the same type in one request
  # def add_flash(type, text, html_safe: false)
  #   flash[:html_safe] = html_safe if html_safe
  #   flash[type] ||= []
  #   flash[type] << text
  # end

  # def error_flash(error, default_message:)
  #   add_flash(:alert, error.message.presence || default_message)
  # end

  def ensure_html_safe_flash
    return unless flash[:html_safe] && flash[:notice]

    flash.delete(:html_safe)

    flash.now[:notice] = if flash[:notice].is_a?(Array)
                           flash[:notice].map(&:html_safe)
                         else
                           flash[:notice].html_safe # rubocop:disable Rails/OutputSafety
                         end
  end
end
