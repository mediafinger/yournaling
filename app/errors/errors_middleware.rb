class ErrorsMiddleware
  ERROR_DEFAULTS = { code: :internal_server_error, status: 500, message: "Sorry, something went wrong." }.freeze

  # Any exceptions that are not configured will be mapped to 500 Internal Server Error (ERROR_DEFAULTS)
  MAP_KNOWN_ERRORS = {
    "AbstractController::ActionNotFound"           => { code: :not_found, status: 404 },
    "ActionController::BadRequest"                 => { code: :bad_request, status: 400 },
    "ActionController::InvalidAuthenticityToken"   => { code: :unprocessable_entity, status: 422 },
    "ActionController::InvalidCrossOriginRequest"  => { code: :unprocessable_entity, status: 422 },
    "ActionController::MethodNotAllowed"           => { code: :method_not_allowed, status: 405 },
    "ActionController::NotImplemented"             => { code: :not_implemented, status: 501 },
    "ActionController::ParameterMissing"           => { code: :bad_request, status: 400 },
    "ActiveRecord::ReadOnlyRecord"                 => { code: :unprocessable_entity, status: 422 },
    "ActionController::RoutingError"               => { code: :not_found, status: 404 },
    "ActionController::UnknownFormat"              => { code: :not_acceptable, status: 406 },
    "ActionController::UnknownHttpMethod"          => { code: :method_not_allowed, status: 405 },
    "ActionDispatch::Http::Parameters::ParseError" => { code: :bad_request, status: 400 },
    "ActiveRecord::RecordInvalid"                  => { code: :unprocessable_entity, status: 422 },
    "ActiveRecord::RecordNotFound"                 => { code: :not_found, status: 404 },
    "ActiveRecord::RecordNotSaved"                 => { code: :unprocessable_entity, status: 422 },
    "ActiveRecord::StaleObjectError"               => { code: :conflict, status: 409 },
    "Rack::QueryParser::InvalidParameterError"     => { code: :bad_request, status: 400 },
    "Rack::QueryParser::ParameterTypeError"        => { code: :bad_request, status: 400 },
    "Rack::Timeout::RequestTimeoutError"           => { code: :timeout, status: 408 },
  }.freeze

  def initialize(app)
    @app = app
  end

  def call(env)
    @app.call(env)
  rescue StandardError => e
    # good place to send the original error to your error tracking service, e.g. Sentry
    self.class.process_error(e, env) # standardize error for logging and response
  end

  class << self
    def process_error(error, env)
      request_id = env["HTTP_X_REQUEST_ID"]

      case error
      # when ContractValidationError
      #   contract_validation_error(error, request_id)
      when CustomError
        custom_error(error, request_id)
      else
        generic_error(error, request_id)
      end
    end

    private

    def generic_error(error, request_id)
      mapped_error = map_error(error, request_id)
      log_error(mapped_error)

      error_body = {
        error: {
          id:  mapped_error.id || request_id,
          code: mapped_error.code,
          message: "#{error.class}: #{error.message}",
        },
      }

      [mapped_error.status, headers, [error_body.to_json]]
    end

    def custom_error(error, request_id)
      log_error(error)

      error_body = {
        error: {
          id: error.id || request_id,
          code: error.code,
          message: "#{error.class}: #{error.message}",
        },
      }

      [error.status, headers, [error_body.to_json]] # TODO: render HTML error page or JSONAPI error object
    end

    def headers
      { "Content-Type" => "application/json" }
    end

    def map_error(error, request_id = nil)
      MappedError.new(
        **ERROR_DEFAULTS.merge(
          MAP_KNOWN_ERRORS.fetch(error.class.name, {}).merge(
            message: error.try(:message) || error,
            original_class: error.class.name,
            backtrace: error.try(:backtrace),
            id: request_id
          )
        )
      )
    end

    def log_error(error)
      klass = error.respond_to?(:original_class) ? error.original_class : error.class.name

      log_entry = [
        klass,
        "message='#{error.message.to_s.encode('UTF-8')}'",
        "code=#{error.code}",
        "status=#{error.status}",
        "id=#{error.id}",
        "stacktrace=#{clean_backtrace(error)}",
      ].join(" ")

      if error.status >= 500
        Rails.logger.error(log_entry)
      else
        Rails.logger.warn(log_entry)
      end
    end

    def clean_backtrace(error)
      return error.backtrace if AppConf.is?(:full_backtrace, true)

      cleaner = ActiveSupport::BacktraceCleaner.new
      cleaner.add_filter   { |line| line.gsub(Rails.root.to_s, '') } # strip the Rails.root prefix
      cleaner.add_silencer { |line| /gems/.match?(line) } # skip any lines from gems, including rails
      cleaner.clean(error.backtrace) # perform the cleanup
    end
  end
end
