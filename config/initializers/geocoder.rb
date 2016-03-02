Geocoder.configure(
  # Geocoding options
  timeout: 3,                      # geocoding service timeout (secs)
  lookup: :google,                 # name of geocoding service (symbol)
  language: :en,                   # ISO-639 language code
  use_https: true,                 # use HTTPS for lookup requests? (if supported)
  api_key: ENV['GOOGLE_API_KEY'],  # API key for geocoding service
  # cache: nil,                    # cache object (must respond to #[], #[]=, and #keys)
  # cache_prefix: 'geocoder:',     # prefix (string) to use for all cache keys

  # Calculation options
  units: :km,                      # :km for kilometers or :mi for miles
  distances: :linear               # :spherical or :linear
)
