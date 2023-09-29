# Currenly almost anything is accepted as a Location, only one of the following has to be given:
# address
# coordinates (lat & long)
# link
# name
# the idea is to usually have enough information to be able to display the location on a map

class Location < ApplicationRecordYidEnabled
  YID_CODE = "loc".freeze

  validates :country_code, presence: true, inclusion: { in: EnglishCountriesForSelectService.call.keys }
  validates :lat, allow_nil: true, numericality: { greater_than_or_equal_to: -90.0, less_than_or_equal_to: 90.0 }
  validates :long, allow_nil: true, numericality: { greater_than_or_equal_to: -180.0, less_than_or_equal_to: 180.0 }
  validates :lat, presence: true, if: :long?
  validates :long, presence: true, if: :lat?

  # TODO: when coordinates are given, check against ISO3166::Country min/max_latitude/_longitude if country makes sense

  validate :ensure_some_info_given
  validate :ensure_valid_link, if: :link?

  def coordinates?
    lat? && long?
  end

  def ensure_some_info_given
    errors.add(:base, "Please provide some info about the location") unless coordinates? || address? || name? || link?
  end

  def ensure_valid_link
    errors.add(:link, "Please provide a valid link starting with http(s)://") unless valid_link?
  end

  # very basic validation, maybe improve, maybe use a gem, maybe don't care more than this?
  def valid_link?
    return false unless link?

    uri = URI.parse(link)
    (uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)) && uri.host.present? && uri.host =~ /.+\..+/

  rescue URI::InvalidURIError
    false
  end
end
