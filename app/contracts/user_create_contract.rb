class UserCreateContract < ApplicationContract
  params do
    required(:email).filled(:string)
    required(:name).filled(:string)
    required(:password).filled(:string)
  end

  rule(:email).validate(:email)

  rule(:name) do
    key.failure("name between 3 and 255 characters required") if key? && !(3..255).include?(value.length)
  end

  rule(:password) do
    key.failure("password between 10 and 72 characters required") if key? && !(10..72).include?(value.length)
  end
end
