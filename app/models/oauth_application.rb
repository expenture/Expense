class OAuthApplication < Doorkeeper::Application
  belongs_to :user, foreign_key: :owner_id, optional: true
  has_many :oauth_access_grant, foreign_key: :application_id
  has_many :oauth_access_token, foreign_key: :application_id
end
