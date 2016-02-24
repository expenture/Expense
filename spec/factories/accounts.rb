FactoryGirl.define do
  factory :account do
    user { create(:user, :confirmed) }
    uid { "#{user.id}-#{SecureRandom.uuid}" }
    name "My Account"

    trait :default do
      after(:create) do |instance|
        user = instance.user
        user.default_account_uid = instance.uid
        user.save!
      end
    end
  end
end
