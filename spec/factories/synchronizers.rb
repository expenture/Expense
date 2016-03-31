FactoryGirl.define do
  factory :synchronizer do
    user { create(:user, :confirmed) }
    uid { "#{user.id}-#{SecureRandom.uuid}" }
    type 'base'
    name "My Syncer"
  end
end
