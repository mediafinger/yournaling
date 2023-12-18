class Location < ApplicationRecordYidEnabled
  YID_CODE = "loc".freeze

  belongs_to :team, inverse_of: :locations, foreign_key: "team_yid"

  # validates :address # TODO: with dry-schema
  validates :lat, allow_nil: true,
    numericality: { greater_than_or_equal_to: BigDecimal("-90.0"), less_than_or_equal_to: BigDecimal("90.0") }
  validates :long, allow_nil: true,
    numericality: { greater_than_or_equal_to: BigDecimal("-180.0"), less_than_or_equal_to: BigDecimal("180.0") }
  validates :name, presence: true, uniqueness: { scope: :team_yid }
  validates :url, presence: true # TODO: ensure URL valid or check for 200 response?
end
