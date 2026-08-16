# frozen_string_literal: true

module MemoryFormHandling
  extend ActiveSupport::Concern

  private

  def permit_memory_params(additional_keys: [])
    params.expect(
      memory: [
        :memo,
        :visibility,
        *additional_keys,
        *MemoryInsightAttacher::INSIGHT_PARAM_KEYS,
      ]
    )
  end
end
