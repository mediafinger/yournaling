# used by the ErrorsMiddleware to map any non-CustomError to our format for logging and displaying
class MappedError < CustomError
  attr_reader :original_class

  def initialize(message:, status:, code:, original_class:, id: nil, backtrace: nil)
    @original_class = original_class
    super(message, status:, code:, id:, backtrace:)
  end
end
