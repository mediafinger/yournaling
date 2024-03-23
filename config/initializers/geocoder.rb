Geocoder.configure(
  # Geocoding options
  # timeout: 3,                 # geocoding service timeout (secs)
  # lookup: :nominatim,         # name of geocoding service (symbol)
  # ip_lookup: :ipinfo_io,      # name of IP address geocoding service (symbol)
  # language: :en,              # ISO-639 language code
  # use_https: false,           # use HTTPS for lookup requests? (if supported)
  # http_proxy: nil,            # HTTP proxy server (user:pass@host:port)
  # https_proxy: nil,           # HTTPS proxy server (user:pass@host:port)
  # api_key: nil,               # API key for geocoding service
  # cache: nil,                 # cache object (must respond to #[], #[]=, and #del)

  # Exceptions that should not be rescued by default
  # (if you want to implement custom error handling);
  # supports SocketError and Timeout::Error
  # always_raise: [],

  # Calculation options
  # units: :mi,                 # :km for kilometers or :mi for miles
  # distances: :linear          # :spherical or :linear

  # Cache configuration
  # cache_options: {
  #   expiration: 2.days,
  #   prefix: 'geocoder:'
  # }
)



Geocoder.configure(
  # ip_lookup: :ipinfo_io,      # name of IP address geocoding service (symbol)
  # http_proxy: nil,            # HTTP proxy server (user:pass@host:port)
  # https_proxy: nil,           # HTTPS proxy server (user:pass@host:port)

  # configure services
  timeout: 2,
  cache: nil,                   # cache object (must respond to #[], #[]=, and #del) / use Redis?!
  language: :en,                # ISO-639 language code
  use_https: true,              # use HTTPS for lookup requests? (if supported)

  lookup: :geoapify,            # name of geocoding service (symbol)

  # https://github.com/alexreisner/geocoder/blob/master/README_API_GUIDE.md#geoapify-geoapify
  geoapify: {
    api_key: AppConf.geoapify_api_key,
    timeout: 2,
    limit: 5,
    autocomplete: true
  },

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
  distances: :spherical,         # :spherical or :linear

  # Cache configuration
  cache_options: {
    expiration: 8.days,
    prefix: "geocoding:",
  },
)

# set stubs for development and test environments, instead of using a real API
#
if AppConf.is?(:environment, :test)
  Geocoder.configure(lookup: :test)

  Geocoder::Lookup::Test.add_stub(
    "New York, US", [
      {
        "properties" => {
          "coordinates"  => [40.7143528, -74.0059731],
          "lat"          => 40.7143528,
          "lon"          => -74.0059731,
          "address"      => "New York, NY, USA",
          "country"      => "United States",
          "country_code" => "US",
        },
      },
    ]
  )

  Geocoder::Lookup::Test.set_default_stub(
    [
      {
        "properties" => {
          "coordinates"  => [45.0, 0.0],
          "lat"          => 45.0,
          "lon"          => 0.0,
          "address"      => "33660 Puynormand, France",
          "country"      => "France",
          "country_code" => "FR",
        },
      },
    ]
  )
end
