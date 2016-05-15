json.key_format!(camelize: :lower) if camelize_keys

json.error @error if @error

json.oauth_applications @oauth_applications, partial: '_models/oauth_application', as: :oauth_application
