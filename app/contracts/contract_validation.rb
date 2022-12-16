module ContractValidation
  def self.validate!(contract, params)
    result = contract.call(**params)

    raise ParamsValidationError, result if result.failure?

    result.to_h
  end
end
