# frozen_string_literal: true

class IdContract < ApplicationContract
  params do
    required(:id).filled(:string)
  end

  rule(:id).validate(:uuid)
end
