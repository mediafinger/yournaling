# https://github.com/alexreisner/geocoder

Geocoder.configure(
  # ip_lookup: :ipinfo_io,      # name of IP address geocoding service (symbol)
  # http_proxy: nil,            # HTTP proxy server (user:pass@host:port)
  # https_proxy: nil,           # HTTPS proxy server (user:pass@host:port)

  # configure services
  timeout: 2,
  cache: Redis.new,
  language: :en,                # ISO-639 language code
  use_https: true,              # use HTTPS for lookup requests? (if supported)

  # lookup: :nominatim,         # name of geocoding service (symbol)
  lookup: :mapbox,

  # https://github.com/alexreisner/geocoder/blob/master/README_API_GUIDE.md#mapbox-mapbox
  mapbox: {
    api_key: AppConf.geocoding_mapbox_api_key,
    timeout: 5,
  },

  # https://github.com/alexreisner/geocoder/blob/master/README_API_GUIDE.md#herenokia-here
  here: {},

  # https://github.com/alexreisner/geocoder/blob/master/README_API_GUIDE.md#geoapify-geoapify
  geoapify: {},

  # raisable exceptions:
  #
  # SocketError
  # Timeout::Error
  # Geocoder::OverQueryLimitError
  # Geocoder::RequestDenied
  # Geocoder::InvalidRequest
  # Geocoder::InvalidApiKey
  # Geocoder::ServiceUnavailable
  #
  always_raise: :all,

  # Calculation options
  units: :km,                 # :km for kilometers or :mi for miles
  distances: :linear,         # :spherical or :linear

  # Cache configuration
  cache_options: {
    expiration: 8.days,
    prefix: "geocoding:",
  },
)

# set stubs for development and test environments, instead of using a real API
#
unless AppConf.production_env
  Geocoder.configure(lookup: :test)

  Geocoder::Lookup::Test.add_stub(
    "New York, US", [
      {
        "coordinates"  => [40.7143528, -74.0059731],
        "address"      => "New York, NY, USA",
        "country"      => "United States",
        "country_code" => "US",
      },
    ]
  )

  Geocoder::Lookup::Test.set_default_stub(
    [
      {
        "coordinates"  => [45.0, 0.0],
        "address"      => "33660 Puynormand, France",
        "country"      => "France",
        "country_code" => "FR",
      },
    ]
  )
end
