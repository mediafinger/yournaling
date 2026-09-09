class ParamsTypeError < CustomError
  def initialize(key:, got:, expected:)
    message = ":#{key} contained '#{got}' expected '#{expected}'"

    super(message, code: :bad_request, status: 400)
  end
end
