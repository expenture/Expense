FactoryGirl.define do
  # Warning: this factory is only for testing, syncing accounts should be
  # create by a syncer in normal situations
  factory :syncing_account do
    synchronizer_uid { create(:synchronizer).uid }
    user { create(:user, :confirmed) }
    uid { "#{user.id}-#{SecureRandom.uuid}" }
    name "My Account"
  end
end
