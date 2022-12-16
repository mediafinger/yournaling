# Define custom errors by inheriting from the generic CustomError:
#
# class SpecificError < CustomError
#   def initialize(parameter)
#     super("Error message with #{parameter}", code: :error_code, status: 444)
#   end
# end
#
class CustomError < StandardError
  attr_reader :backtrace, :code, :id, :message, :status

  def initialize(message = nil, status: nil, code: nil, id: nil, backtrace: nil)
    @message = message || "Sorry, something went wrong."
    @status = status || 500
    @code = code || :internal_server_error
    @id = id || SecureRandom.uuid
    @backtrace = backtrace || []
  end

  def to_s
    "#{code} #{message}"
  end
end
