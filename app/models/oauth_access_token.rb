class OAuthAccessToken < Doorkeeper::AccessToken
  belongs_to :user, foreign_key: :resource_owner_id
  belongs_to :oauth_application, foreign_key: :application_id, optional: true

  validates :user, presence: true
end
