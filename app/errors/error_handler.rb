module ErrorHandler
  ERROR_DEFAULTS = { code: :internal_server_error, status: 500, message: "Sorry, something went wrong." }.freeze

  # https://github.com/rails/rails/blob/master/guides/source/configuring.md#configuring-action-dispatch
  # https://github.com/rails/rails/blob/master/guides/source/layouts_and_rendering.md#rendering-raw-body
  # Any exceptions that are not configured will be mapped to 500 Internal Server Error (ERROR_DEFAULTS)
  MAP_RAILS_ERRORS = {
    "AbstractController::ActionNotFound"           => { code: :not_found, status: 404 },
    "ActionController::RoutingError"               => { code: :not_found, status: 404 },
    "ActiveRecord::RecordNotFound"                 => { code: :not_found, status: 404 },
    "ActionController::MethodNotAllowed"           => { code: :method_not_allowed, status: 405 },
    "ActionController::UnknownHttpMethod"          => { code: :method_not_allowed, status: 405 },
    "ActionController::NotImplemented"             => { code: :not_implemented, status: 501 },
    "ActionController::UnknownFormat"              => { code: :not_acceptable, status: 406 },
    "ActiveRecord::StaleObjectError"               => { code: :conflict, status: 409 },
    "ActionController::InvalidAuthenticityToken"   => { code: :unprocessable_entity, status: 422 },
    "ActionController::InvalidCrossOriginRequest"  => { code: :unprocessable_entity, status: 422 },
    "ActiveRecord::RecordInvalid"                  => { code: :unprocessable_entity, status: 422 },
    "ActiveRecord::RecordNotSaved"                 => { code: :unprocessable_entity, status: 422 },
    "ActionDispatch::Http::Parameters::ParseError" => { code: :bad_request, status: 400 },
    "ActionController::BadRequest"                 => { code: :bad_request, status: 400 },
    "ActionController::ParameterMissing"           => { code: :bad_request, status: 400 },
    "Rack::QueryParser::ParameterTypeError"        => { code: :bad_request, status: 400 },
    "Rack::QueryParser::InvalidParameterError"     => { code: :bad_request, status: 400 },
  }.freeze

  def self.included(klass)
    klass.class_eval do
      # Ensure all Rails errors and other unhandled errors are treated
      rescue_from ::StandardError do |e|
        mapped_error = map_error(e)
        log_error(mapped_error, original_error: e)
        render_error_view(code: mapped_error.code, status: mapped_error.status, message: mapped_error.message)
      end

      # Rescue errors from internal API calls made with ChimeraHttpClient
      # rescue_from ::ChimeraHttpClient::Error do |e|
      #   err = MappedError.new(code: e.code, status: e.code, message: e.message, original_class: e.class.name)
      #   log_error(err, original_error: e)
      #   render_error_view(code: err.original_class_to_code, status: err.code, message: e.class.name)
      # end

      # Ensure all our custom errors are handled the same way
      rescue_from CustomError do |e|
        log_error(e, original_error: e)
        render_error_view(code: e.code, status: e.status, message: e.message)
      end

      # When someone is accessing a page without the necessary permissions
      # rescue_from ::Pundit::NotAuthorizedError do |e|
      #   error = CustomError.new("Pundit: #{e.message}", code: :unauthorized, status: 401)
      #   log_error(error, original_error: e)
      #   render_error_view(code: error.code, status: error.status, message: "Not permitted")
      # end

      # This happens when we forget to explicitly allow actions
      # rescue_from ::Pundit::AuthorizationNotPerformedError, ::Pundit::PolicyScopingNotPerformedError do |e|
      #   error = CustomError.new("Pundit: #{e.message}", code: :no_authorization, status: 500)
      #   log_error(error, original_error: e)
      #   render_error_view(code: error.code, status: error.status, message: "Could not determine permissions")
      # end
    end
  end

  private

  def map_error(error)
    MappedError.new(
      **ERROR_DEFAULTS.merge(
        MAP_RAILS_ERRORS.fetch(error.class.name, {}).merge(
          message: error.message, original_class: error.class.name, backtrace: error.backtrace
        )
      )
    )
  end

  def render_error_view(code:, status:, message:)
    # rendered_message = AppConf.production_env ? ERROR_DEFAULTS[:message] : message

    render "pages/error", locals: { code:, message:, status: }, status:
  end

  def log_error(error, original_error: nil)
    klass = error.respond_to?(:original_class) ? error.original_class : error.class.name

    log_entry = [
      klass,
      "message='#{error.message.to_s.encode('UTF-8')}'", # to avoid Encoding::UndefinedConversionError
      "code=#{error.code}",
      "status=#{error.status}",
      "id=#{error.id}",
      "stacktrace=#{clean_backtrace(original_error.presence || error)}",
    ].join(" ")

    if error.status >= 500
      logger.error(log_entry)
    else
      logger.warn(log_entry)
    end
  end

  def logger
    @logger ||= Rails.logger
  end

  def clean_backtrace(error)
    return error.backtrace if AppConf.is?(:full_backtrace, true)

    cleaner = ActiveSupport::BacktraceCleaner.new
    cleaner.add_filter   { |line| line.gsub(Rails.root.to_s, "") } # strip the Rails.root prefix
    cleaner.add_silencer { |line| line.include?("gems") } # skip any lines from gems, including rails
    cleaner.clean(error.backtrace) # perform the cleanup
  end
end
