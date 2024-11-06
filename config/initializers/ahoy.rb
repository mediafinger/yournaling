# https://github.com/ankane/ahoy

module Ahoy
  class Store < Ahoy::DatabaseStore
    # def authenticate(data)
      # disables automatic linking of visits and users - needed for GDPR compliance ?
      #
      # alternative, to not store visit details linked to users for long:
      # store full details, use a job to aggregate data (e.g. once per week)
      # Ahoy::Visit.rollup("Visits", interval: "weekly")
      # delete user_id, token & other ID-data after aggregation has happened
      # delete visits after 5 weeks, as they don't seem to hold long-term value
      # keep anonymized aggregated data for 2 years
    # end

    # handle more data in the visit via JS
    # def track_visit(data)
      # data[:accept_language] = request.headers["Accept-Language"]
      # data[:controller_...] = controller....
      # super(data)
    # end

    # exclude requests from being tracked
    # Ahoy.exclude_method = lambda do |controller, request|
    #   request.ip == "192.168.1.1"
    # end
  end
end

Ahoy.mask_ips = true # GDPR compliance - impossible to link back to connection, done before geo-location
Ahoy.cookies = :none # GDPR compliance - no cookies set, instead anonymity sets will be used
# TODO: also set in the JS setup: `ahoy.configure({cookies: false});``

# set to true for JavaScript tracking
Ahoy.api = false

# set to true for geocoding (and add the geocoder gem to your Gemfile)
# we recommend configuring local geocoding as well
# see https://github.com/ankane/ahoy#geocoding
Ahoy.geocode = false
