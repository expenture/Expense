class OAuthAccessGrant < Doorkeeper::AccessGrant
  belongs_to :user, foreign_key: :resource_owner_id
  belongs_to :oauth_application, foreign_key: :application_id, optional: true

  validates :user, :oauth_application, presence: true
end
