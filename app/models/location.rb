class Location < ApplicationRecordYidEnabled
  YID_CODE = "loc".freeze

  belongs_to :team, inverse_of: :locations, foreign_key: "team_yid"

  has_many :memories, class_name: "Memory", foreign_key: "location_yid", primary_key: "yid", inverse_of: :location,
    dependent: :nullify

  multisearchable(
    against: %i[name country_code address],
    additional_attributes: ->(location) { { team_yid: location.team_yid } }
  )

  attr_readonly :team_yid

  normalizes :country_code, with: ->(country_code) { country_code.strip.downcase }
  normalizes :name, with: ->(name) { name.strip }
  normalizes :url, with: ->(url) {
    ActionDispatch::Http::URL.full_url_for(host: url.strip, protocol: "https") if url.present?
  }, apply_to_nil: false

  validate :address_or_coordinates_or_url_given
  validates :country_code, presence: true, inclusion: { in: CountriesEnForSelectService.call.keys }
  validates :lat, allow_nil: true,
    numericality: { greater_than_or_equal_to: BigDecimal("-90.0"), less_than_or_equal_to: BigDecimal("90.0") }
  validates :long, allow_nil: true,
    numericality: { greater_than_or_equal_to: BigDecimal("-180.0"), less_than_or_equal_to: BigDecimal("180.0") }
  validates :name, presence: true, uniqueness: { scope: :team_yid }
  validates :team_yid, presence: true, uniqueness: { scope: :name }

  after_validation :geocode, if: ->(location) { calculate_coordinates?(location) }
  after_validation :reverse_geocode, if: ->(location) { get_address?(location) }
  after_validation :create_gmaps_url, if: ->(location) { location.url.nil? }
  after_validation :set_address, if: ->(location) { location.address.blank? }

  # NOTE: this adds the `geocode` method
  geocoded_by :address_with_cc do |location, results|
    next unless results.any?

    geocoding_result = results.first.data["properties"] # ignore other API results

    location.lat = geocoding_result["lat"]
    location.long = geocoding_result["lon"]
    location.country_code = geocoding_result["country_code"]
    location.geocoded_address[:country_code] = geocoding_result["country_code"]
  end

  reverse_geocoded_by :lat, :long do |location, results|
    next unless results.any?

    geocoding_result = results.first.data["properties"] # ignore other API results

    location.country_code = geocoding_result["country_code"]
    # NOTE: depending on the result more or less information will be returned
    location.geocoded_address[:name] = geocoding_result["name"] || geocoding_result["result_type"]
    location.geocoded_address[:country_code] = geocoding_result["country_code"]
    location.geocoded_address[:state] = geocoding_result["state"]
    location.geocoded_address[:state_district] = geocoding_result["state_district"]
    location.geocoded_address[:county] = geocoding_result["county"]
    location.geocoded_address[:zip_code] = geocoding_result["postcode"]
    location.geocoded_address[:city] = geocoding_result["city"]
    location.geocoded_address[:city_district] = geocoding_result["district"]
    location.geocoded_address[:city_neighbourhood] = geocoding_result["neighbourhood"]
    location.geocoded_address[:city_suburb] = geocoding_result["suburb"]
    location.geocoded_address[:street] = geocoding_result["street"]
    location.geocoded_address[:housenumber] = geocoding_result["housenumber"]
    location.geocoded_address[:lat] = geocoding_result["lat"]
    location.geocoded_address[:long] = geocoding_result["lon"]
    location.geocoded_address[:full_address] = geocoding_result["formatted"]
  end

  # Geocoder.search(address, params: {bias: "countrycode:country_code" })
  # "https://api.geoapify.com/v1/geocode/search?text=#{address}&filter=countrycode:#{country_code}&apiKey=#{AppConf.geoapify_api_key}"

  def coordinates
    [lat, long]
  end

  def coordinates_changed?
    lat_changed? || long_changed?
  end

  def gmaps_coordinates_url
    "https://www.google.com/maps/place/#{lat},#{long}"
  end

  def map(width:, height:, style: "osm-carto", zoom: 14)
    "https://maps.geoapify.com/v1/staticmap?" \
      "style=#{style}&width=#{width}&height=#{height}&" \
      "center=lonlat:#{long},#{lat}&zoom=#{zoom}&" \
      "type:awesome;color:%231db510;size:x-large&apiKey=#{AppConf.geoapify_api_key}"
  end

  private

  def address_with_cc
    [address, country_code&.upcase].compact.join(", ")
  end

  def address_or_coordinates_or_url_given
    return if address.present? || (lat.present? && long.present?) || url.present?

    errors.add(:base, "Address, Coordinates, or URL must be provided")
  end

  def create_gmaps_url
    self.url = gmaps_coordinates_url
  end

  # NOTE: calculate new coordinates when the address changes, unless the coordinates have been changed as well
  def calculate_coordinates?(location)
    return location.coordinates.compact.blank? && location.address.present? if location.new_record?

    location.country_code_changed? ||
      location.address.present? && location.address_changed? && !location.coordinates_changed?
  end

  # NOTE: fetch new address when the coordinates change, unless the address has been changed as well
  def get_address?(location)
    return location.address.blank? && location.coordinates.present? if location.new_record?

    location.country_code_changed? ||
      location.coordinates.present? && location.coordinates_changed? && !location.address_changed?
  end

  def set_address
    self.address = geocoded_address[:full_address]

    return if address.present?

    self.address = [
      geocoded_address[:street],
      geocoded_address[:housenumber],
      geocoded_address[:zip_code],
      geocoded_address[:city],
      geocoded_address[:county],
      geocoded_address[:state],
    ].compact.join(", ")
  end
end
