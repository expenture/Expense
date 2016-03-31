# == Schema Information
#
# Table name: oauth_access_tokens
#
# *id*::                <tt>integer, not null, primary key</tt>
# *resource_owner_id*:: <tt>integer</tt>
# *application_id*::    <tt>integer</tt>
# *token*::             <tt>text, not null</tt>
# *refresh_token*::     <tt>text</tt>
# *expires_in*::        <tt>integer</tt>
# *revoked_at*::        <tt>datetime</tt>
# *created_at*::        <tt>datetime, not null</tt>
# *scopes*::            <tt>string</tt>
#
# Indexes
#
#  index_oauth_access_tokens_on_refresh_token      (refresh_token) UNIQUE
#  index_oauth_access_tokens_on_resource_owner_id  (resource_owner_id)
#  index_oauth_access_tokens_on_token              (token) UNIQUE
#--
# == Schema Information End
#++

class OAuthAccessToken < Doorkeeper::AccessToken
  belongs_to :user, foreign_key: :resource_owner_id
  belongs_to :oauth_application, foreign_key: :application_id, optional: true

  validates :user, presence: true
end
