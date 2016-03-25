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

    # Warning: this factory is only for testing, syncing accounts should be
    # create by a syncer in normal situations
    trait :syncing do
      synchronizer_uid { create(:synchronizer).uid }
    end
  end
end
