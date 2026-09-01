# frozen_string_literal: true

module ContractValidation
  def self.validate!(contract, params)
    result = contract.call(**params)

    raise ParamsValidationError.new(result) if result.failure?

    result.to_h
  end
end
