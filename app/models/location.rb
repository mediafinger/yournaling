class Location < ApplicationRecordYidEnabled
  YID_CODE = "loc".freeze

  belongs_to :team, inverse_of: :locations, foreign_key: "team_yid"

  normalizes :country_code, with: ->(country_code) { country_code.strip.downcase }
  normalizes :name, with: ->(name) { name.strip }
  normalizes :url, with: ->(url) { ActionDispatch::Http::URL.full_url_for(host: url.strip, protocol: "https") }

  # validates :address # TODO: with dry-schema
  validates :country_code, presence: true, inclusion: { in: CountriesEnForSelectService.call.keys }
  validates :lat, allow_nil: true,
    numericality: { greater_than_or_equal_to: BigDecimal("-90.0"), less_than_or_equal_to: BigDecimal("90.0") }
  validates :long, allow_nil: true,
    numericality: { greater_than_or_equal_to: BigDecimal("-180.0"), less_than_or_equal_to: BigDecimal("180.0") }
  validates :team_yid, presence: true, uniqueness: { scope: :name }
  validates :name, presence: true, uniqueness: { scope: :team_yid }
  validates :url, presence: true # TODO: ensure URL valid or check for 200 response?

  # Geocoder.search(address, params: {filter: "countrycode:country_code" })
  # "https://api.geoapify.com/v1/geocode/search?text=#{address}&filter=countrycode:#{country_code}&apiKey=#{AppConf.geoapify_api_key}"
end
