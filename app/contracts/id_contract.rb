class IdContract < ApplicationContract
  params do
    required(:id).filled(:string)
  end

  rule(:uuid).validate(:uuid)
end
