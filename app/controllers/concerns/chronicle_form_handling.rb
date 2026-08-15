# frozen_string_literal: true

module ChronicleFormHandling
  extend ActiveSupport::Concern

  private

  def load_chronicle_form_resources(team:)
    @team_pictures = Picture.where(team:).with_attached_file.order(created_at: :desc)
    @team_locations = Location.where(team:).order(created_at: :desc)
    @team_thoughts = Thought.where(team:).order(created_at: :desc)
    @team_weblinks = Weblink.where(team:).order(created_at: :desc)
  end

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
        { chronicle_entries_attributes: [%i[id entry_type entry_id position _destroy]] },
      ]
    )
  end
end
