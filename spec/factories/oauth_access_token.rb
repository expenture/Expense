FactoryGirl.define do
  factory :oauth_access_token, class: Doorkeeper::AccessToken do
    resource_owner_id { create(:user, :confirmed).id }
    expires_in { 2.hours }
  end
end
