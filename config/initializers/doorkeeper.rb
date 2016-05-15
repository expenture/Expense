Doorkeeper.configure do
  # Change the ORM that doorkeeper will use (needs plugins)
  orm :active_record

  # This block will be called to check whether the resource owner is authenticated or not.
  resource_owner_authenticator do
    current_user || redirect_to(new_user_session_url)
  end

  # If you want to restrict access to the web interface for adding oauth authorized applications, you need to declare the block below.
  # admin_authenticator do
  #   # Put your admin authentication logic here.
  #   # Example implementation:
  #   Admin.find_by_id(session[:admin_id]) || redirect_to(new_admin_session_url)
  # end

  # Authorization Code expiration time (default 10 minutes).
  # authorization_code_expires_in 10.minutes

  # Access token expiration time (default 2 hours).
  # If you want to disable expiration, set this to nil.
  # access_token_expires_in 2.hours

  # Assign a custom TTL for implicit grants.
  # custom_access_token_expires_in do |oauth_client|
  #   oauth_client.application.additional_settings.implicit_oauth_expiration
  # end

  # Use a custom class for generating the access token.
  # https://github.com/doorkeeper-gem/doorkeeper#custom-access-token-generator
  # access_token_generator "::Doorkeeper::JWT"

  # Reuse access token for the same resource owner within an application (disabled by default)
  # Rationale: https://github.com/doorkeeper-gem/doorkeeper/issues/383
  # reuse_access_token

  # Issue access tokens with refresh token (disabled by default)
  use_refresh_token

  # Provide support for an owner to be assigned to each registered application (disabled by default)
  # Optional parameter :confirmation => true (default false) if you want to enforce ownership of
  # a registered application
  # Note: you must also run the rails g doorkeeper:application_owner generator to provide the necessary support
  enable_application_owner :confirmation => false

  # Define access token scopes for your provider
  # For more information go to
  # https://github.com/doorkeeper-gem/doorkeeper/wiki/Using-Scopes
  # default_scopes  :default
  # optional_scopes :write, :update

  # Change the way client credentials are retrieved from the request object.
  # By default it retrieves first from the `HTTP_AUTHORIZATION` header, then
  # falls back to the `:client_id` and `:client_secret` params from the `params` object.
  # Check out the wiki for more information on customization
  # client_credentials :from_basic, :from_params

  # Change the way access token is authenticated from the request object.
  # By default it retrieves first from the `HTTP_AUTHORIZATION` header, then
  # falls back to the `:access_token` or `:bearer_token` params from the `params` object.
  # Check out the wiki for more information on customization
  # access_token_methods :from_bearer_authorization, :from_access_token_param, :from_bearer_param

  # Change the native redirect uri for client apps
  # When clients register with the following redirect uri, they won't be redirected to any server and the authorization code will be displayed within the provider
  # The value can be any string. Use nil to disable this feature. When disabled, clients must provide a valid URL
  # (Similar behaviour: https://developers.google.com/accounts/docs/OAuth2InstalledApp#choosingredirecturi)
  #
  # native_redirect_uri 'urn:ietf:wg:oauth:2.0:oob'

  # Forces the usage of the HTTPS protocol in non-native redirect uris (enabled
  # by default in non-development environments). OAuth2 delegates security in
  # communication to the HTTPS protocol so it is wise to keep this enabled.
  #
  # force_ssl_in_redirect_uri !Rails.env.development?

  # Specify what grant flows are enabled in array of Strings. The valid
  # strings and the flows they enable are:
  #
  # "authorization_code" => Authorization Code Grant Flow
  # "implicit"           => Implicit Grant Flow
  # "password"           => Resource Owner Password Credentials Grant Flow
  # "client_credentials" => Client Credentials Grant Flow
  #
  # If not specified, Doorkeeper enables authorization_code and
  # client_credentials.
  #
  # implicit and password grant flows have risks that you should understand
  # before enabling:
  #   http://tools.ietf.org/html/rfc6819#section-4.4.2
  #   http://tools.ietf.org/html/rfc6819#section-4.4.3
  #
  grant_flows %w(authorization_code client_credentials implicit password)

  # Resource Owner Credentials Grant Flow
  resource_owner_from_credentials do |routes|
    username = params[:username]
    password = params[:password]

    case username

    # Facebook Access Token Auth
    when 'facebook:access_token'
      fb_app_data = FacebookService.app_data_from_facebook_access_token(password)

      # the Facebook access token is valid, get the user's data from Facebook
      if fb_app_data.is_a?(Hash)
        # validate the app of the access token
        if fb_app_data[:id] == FacebookService.app_id
          # return the user from Facebook
          User.from_facebook_access_token(password)

        # the Facebook access token does not belongs to this Facebook app, return
        else
          nil
        end

      # the Facebook access token is not valid, return
      else
        nil
      end

    # Password Auth
    else
      user = User.find_for_database_authentication(email: username)
      user = User.find_for_database_authentication(mobile: username) if user.blank?

      if user.present? && user.confirmed?
        if user.access_locked?
          user.unlock_access! if user.locked_at < Time.now - User.unlock_in
        end

        if user.access_locked?
          # return
          nil
        elsif user.valid_password?(password)
          user.failed_attempts = 0 && user.save! if user.failed_attempts > 0

          # return
          user
        else
          user.failed_attempts += 1
          user.save!
          user.lock_access! if user.failed_attempts > User.maximum_attempts

          # return
          nil
        end
      end
    end
  end

  # Under some circumstances you might want to have applications auto-approved,
  # so that the user skips the authorization step.
  # For example if dealing with a trusted application.
  # skip_authorization do |resource_owner, client|
  #   client.superapp? or resource_owner.admin?
  # end

  # WWW-Authenticate Realm (default "Doorkeeper").
  realm ENV['APP_NAME']
end

# Override the PasswordAccessTokenRequest class to enforce client validation
# and allow application creating on the fly
module Doorkeeper
  module OAuth
    class PasswordAccessTokenRequest
      def initialize(server, credentials, resource_owner, parameters = {})
        @server          = server
        @resource_owner  = resource_owner
        @credentials     = credentials
        @parameters      = parameters
        @original_scopes = parameters[:scope]

        if credentials
          @client = Application.by_uid_and_secret credentials.uid,
                                                  credentials.secret
        end
      end

      def validate_client
        if !client &&
           params[:client_uid] &&
           params[:client_type] &&
           params[:client_name]
          @client = OAuthApplication.where(uid: params[:client_uid], owner: resource_owner).first_or_create do |new_oauth_application|
            new_oauth_application.type = params[:client_type]
            new_oauth_application.name = params[:client_name]
          end
        end

        !!client && client.persisted?
      end

      def params
        @parameters
      end
    end
  end

  class Application
    self.inheritance_column = nil
  end
end
