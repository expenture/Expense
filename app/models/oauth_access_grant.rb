# == Schema Information
#
# Table name: oauth_access_grants
#
# *id*::                <tt>integer, not null, primary key</tt>
# *resource_owner_id*:: <tt>integer, not null</tt>
# *application_id*::    <tt>integer, not null</tt>
# *token*::             <tt>string, not null</tt>
# *expires_in*::        <tt>integer, not null</tt>
# *redirect_uri*::      <tt>text, not null</tt>
# *created_at*::        <tt>datetime, not null</tt>
# *revoked_at*::        <tt>datetime</tt>
# *scopes*::            <tt>string</tt>
#
# Indexes
#
#  index_oauth_access_grants_on_token  (token) UNIQUE
#--
# == Schema Information End
#++

class OAuthAccessGrant < Doorkeeper::AccessGrant
  belongs_to :user, foreign_key: :resource_owner_id
  belongs_to :oauth_application, foreign_key: :application_id, optional: true

  validates :user, :oauth_application, presence: true
end
