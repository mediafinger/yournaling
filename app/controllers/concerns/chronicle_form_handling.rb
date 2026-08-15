# frozen_string_literal: true

module ChronicleFormHandling
  extend ActiveSupport::Concern

  private

  def permit_chronicle_params(additional_keys: [])
    params.expect(
      chronicle: [
        :name,
        :notice,
        :start_date,
        :end_date,
        :visibility,
        *additional_keys,
        *ChronicleAttachableInsights::INSIGHT_PARAM_KEYS,
        { entries_attributes: [%i[id entry_type entry_id position _destroy]] },
      ]
    )
  end
end
