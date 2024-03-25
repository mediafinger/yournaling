class ChronicleLocation < ApplicationRecordYidEnabled
  YID_CODE = "cronloc".freeze

  belongs_to :team, inverse_of: :chronicle_locations, foreign_key: "team_yid"
  belongs_to :chronicle, inverse_of: :chronicle_locations, foreign_key: "chronicle_yid"
  belongs_to :location, inverse_of: :chronicle_locations, foreign_key: "location_yid"

  attr_readonly :team_yid

  delegate :name, to: :location
end
