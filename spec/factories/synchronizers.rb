FactoryGirl.define do
  factory :synchronizer do
    user { create(:user, :confirmed) }
    uid { "#{user.id}-#{SecureRandom.uuid}" }
    type nil
    name "My Syncer"
  end
end
