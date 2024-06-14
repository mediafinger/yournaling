class ChronicleWeblink < ApplicationRecordYidEnabled
  YID_CODE = "cronlink".freeze

  belongs_to :team, inverse_of: :chronicle_weblinks, foreign_key: "team_yid"
  belongs_to :chronicle, inverse_of: :chronicle_weblinks, foreign_key: "chronicle_yid"
  belongs_to :weblink, inverse_of: :chronicle_weblinks, foreign_key: "weblink_yid"

  attr_readonly :team_yid

  after_commit :update_chronicle

  delegate :name, to: :location

  private

  def update_chronicle
    chronicle.save # to ensure chronicle.weblinks_order is being updated
  end
end
