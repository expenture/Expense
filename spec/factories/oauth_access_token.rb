FactoryGirl.define do
  factory :oauth_access_token, class: OAuthAccessToken do
    application { create(:oauth_application) }
    user { create(:user, :confirmed) }
    expires_in { 2.hours }
  end
end
