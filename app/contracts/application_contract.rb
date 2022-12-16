class ApplicationContract < Dry::Validation::Contract
  VALID_UUID_REGEX = /\A[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}\z/i

  register_macro(:email) do
    key.failure("email is not valid") if key? && (URI::MailTo::EMAIL_REGEXP =~ value) != 0
  end

  register_macro(:uuid) do
    key.failure("not a valid UUID format") unless VALID_UUID_REGEX.match?(value)
  end
end
