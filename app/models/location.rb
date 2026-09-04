# frozen_string_literal: true

# type: Content
#
class Location < ApplicationRecordForContentAndPosts
  include VisibilityConstrainedByParents

  YID_CODE = "loc"

  # Coordinates embedded in map links from the common providers.
  # All patterns capture `lat` then `long` (WGS84, decimal degrees).
  MAP_URL_COORDINATE_PATTERNS = [
    /@(?<lat>-?\d{1,3}\.\d+),(?<long>-?\d{1,3}\.\d+)/, # google: /maps/@36.7,-2.2,15z or /place/X/@...
    /[?&](?:q|query|ll|sll|center|destination)=(?:loc:)?(?<lat>-?\d{1,3}\.\d+),(?<long>-?\d{1,3}\.\d+)/, # ?q=36.7,-2.2
    /[?&]mlat=(?<lat>-?\d{1,3}\.\d+)&mlon=(?<long>-?\d{1,3}\.\d+)/,  # openstreetmap.org/?mlat=..&mlon=..
    %r{#map=\d+/(?<lat>-?\d{1,3}\.\d+)/(?<long>-?\d{1,3}\.\d+)},     # openstreetmap.org/#map=15/36.7/-2.2
    /!3d(?<lat>-?\d{1,3}\.\d+)!4d(?<long>-?\d{1,3}\.\d+)/,           # google embed !3d..!4d..
    %r{\bgeo:(?<lat>-?\d{1,3}\.\d+),(?<long>-?\d{1,3}\.\d+)},        # geo:36.7,-2.2 URI
    %r{/maps/place/(?<lat>-?\d{1,3}\.\d+),(?<long>-?\d{1,3}\.\d+)},  # /maps/place/36.05,-5.64
  ].freeze

  # Transient input: a pasted map link (Google / Apple / OpenStreetMap …).
  # We parse coordinates out of it on save and then discard it — the canonical
  # map link is always derived from the stored coordinates (see `#gmaps_coordinates_url`).
  attr_accessor :map_url

  belongs_to :team, inverse_of: :locations
  has_many :chronicle_entries, as: :entry, dependent: :destroy
  has_many :chronicles, -> { distinct.reorder("chronicles.created_at DESC") }, through: :chronicle_entries
  has_many :memories, class_name: "Memory", inverse_of: :location,
    dependent: :nullify

  multisearchable(
    against: %i[name country_code address],
    additional_attributes: ->(location) { { team_id: location.team_id } }
  )

  attr_readonly :team_id

  normalizes :country_code, with: ->(country_code) { country_code.strip.downcase }
  normalizes :name, with: ->(name) { name.strip }
  normalizes :url, with: ->(url) {
    ActionDispatch::Http::URL.full_url_for(host: url.strip, protocol: "https") if url.present?
  }, apply_to_nil: false

  validate :locator_given
  validates :country_code, presence: true, inclusion: { in: CountriesEnForSelectService.call.keys }
  validates :lat, allow_nil: true,
    numericality: { greater_than_or_equal_to: BigDecimal("-90.0"), less_than_or_equal_to: BigDecimal("90.0") }
  validates :long, allow_nil: true,
    numericality: { greater_than_or_equal_to: BigDecimal("-180.0"), less_than_or_equal_to: BigDecimal("180.0") }
  validates :name, presence: true, uniqueness: { scope: :team_id }
  validates :team_id, uniqueness: { scope: :name }
  validates :visibility, presence: true, inclusion: { in: VISIBILITY_STATES }

  before_validation :extract_coordinates_from_map_url
  after_validation :safe_geocode, if: ->(location) { calculate_coordinates?(location) }
  after_validation :safe_reverse_geocode, if: ->(location) { get_address?(location) }
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

  # Best-effort extraction of `[lat, long]` from a pasted map link, or nil.
  def self.coordinates_from_map_url(url)
    return if url.blank?

    MAP_URL_COORDINATE_PATTERNS.each do |pattern|
      match = url.match(pattern)
      next unless match

      lat = BigDecimal(match[:lat])
      long = BigDecimal(match[:long])
      next unless lat.between?(-90, 90) && long.between?(-180, 180)

      return [lat, long]
    end

    nil
  end

  def coordinates
    [lat, long]
  end

  # A location is "located" once it has usable coordinates — only then can we
  # show a map and a reliable map link. Address-only locations stay valid but
  # render in a degraded state until geocoding resolves them.
  def located?
    lat.present? && long.present?
  end

  def coordinates_changed?
    lat_changed? || long_changed?
  end

  def gmaps_coordinates_url
    "https://www.google.com/maps/place/#{lat},#{long}"
  end

  # ISO3166 country for `country_code` (a lower-case alpha-2), or nil.
  def country
    ISO3166::Country.find_country_by_alpha2(country_code) if country_code.present?
  end

  # "Spain" — humanised country name, or nil.
  def country_name
    country&.iso_short_name
  end

  # "Spain (ES) 🇪🇸" — name + code + flag, or nil.
  def country_label
    return if country.nil?

    "#{country.iso_short_name} (#{country.alpha2}) #{country.emoji_flag}"
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

  def extract_coordinates_from_map_url
    return if map_url.blank? || located?

    coordinates = self.class.coordinates_from_map_url(map_url)
    self.lat, self.long = coordinates if coordinates
  end

  # A Location must point at a real spot: coordinates, or an address we can
  # geocode, or a map link we can read coordinates from. A bare name + link
  # with no map pin belongs in a Weblink instead.
  def locator_given
    return if address.present? || located?

    if map_url.present?
      errors.add(:map_url,
        "could not be read — paste a Google Maps, Apple Maps, or OpenStreetMap link " \
        "that points at a specific spot, or enter an address or GPS coordinates")
    else
      errors.add(:base,
        "Add an address, GPS coordinates, or a map link. " \
        "To bookmark a place that has no map pin, add a Weblink instead.")
    end
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

  def safe_geocode
    geocode
  rescue Geocoder::Error, SocketError, Timeout::Error => e
    Rails.logger.warn("Geocoding failed for Location: #{e.class} - #{e.message}")
  end

  def safe_reverse_geocode
    reverse_geocode
  rescue Geocoder::Error, SocketError, Timeout::Error => e
    Rails.logger.warn("Reverse geocoding failed for Location: #{e.class} - #{e.message}")
  end
end
