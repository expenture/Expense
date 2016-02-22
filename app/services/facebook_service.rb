# An API wrapper for all connections to Facebook
module FacebookService
  cattr_accessor :mock_mode

  class << self
    def app_id
      ENV['FB_APP_ID']
    end

    def app_secret
      ENV['FB_APP_SECRET']
    end

    def app_access_token
      return @app_access_token if @app_access_token
      @app_access_token = RestClient.get(
        "https://graph.facebook.com/oauth/access_token",
        params: {
          client_id: app_id,
          client_secret: app_secret,
          grant_type: :client_credentials
        }
      ).gsub(/.+=/, '')
    end

    def default_scopes
      ['public_profile', 'email', 'user_friends']
    end

    def default_scopes_string
      default_scopes.join(' ')
    end

    def app_data_from_facebook_access_token(access_token)
      if mock_mode
        return HashWithIndifferentAccess.new({
          id: access_token || Faker::Number.number(12),
          name: Faker::Name.name
        })
      end

      response = RestClient.get(
        "https://graph.facebook.com/v2.5/app",
        params: {
          access_token: access_token
        },
        accept: :json
      )

      data = HashWithIndifferentAccess.new(JSON.parse(response))
    end

    def user_data_fields
      %w(id email name picture.height(512).width(512) cover)
    end

    def user_data_from_facebook_access_token(access_token, fields: user_data_fields)
      if mock_mode
        return HashWithIndifferentAccess.new({
          id: Faker::Number.number(12),
          name: Faker::Name.name,
          email: "#{Faker::Internet.user_name}@facebook.com",
          picture_url: 'http://placehold.it/720x720',
          cover_url: 'http://placehold.it/1024x512'
        })
      end

      response = RestClient.get(
        "https://graph.facebook.com/v2.5/me",
        params: {
          access_token: access_token,
          fields: fields.join(',')
        },
        accept: :json
      )

      data = HashWithIndifferentAccess.new(JSON.parse(response))

      data[:email] = "#{data[:id]}@facebook.id" unless data[:email]

      data[:picture_url] = data[:picture] &&
                           data[:picture][:data] &&
                           data[:picture][:data][:url]
      data[:cover_url] = data[:cover] &&
                         data[:cover][:source]

      return data
    end

    def user_friends_from_facebook_access_token(access_token)
      response = RestClient.get(
        "https://graph.facebook.com/v2.5/me/friends",
        params: {
          access_token: access_token,
          limit: 10000
        },
        accept: :json
      )

      data = HashWithIndifferentAccess.new(JSON.parse(response))

      return data[:data]
    end
  end
end
