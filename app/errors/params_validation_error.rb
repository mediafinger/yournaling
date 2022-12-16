class ParamsValidationError < CustomError
  attr_reader :validation_result

  def initialize(validation_result)
    @validation_result = validation_result

    messages = validation_result.errors.map { |e| "#{e.path} #{e.text}" }.join(", ")

    super(messages, code: :unprocessable_entity, status: 422)
  end
end
