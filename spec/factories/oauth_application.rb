FactoryGirl.define do
  factory :oauth_application, class: OAuthApplication do
    name { Faker::App.name }
  end
end
