FactoryGirl.define do
  factory :transaction do
    account { create(:account) }
    uid { "#{account.uid}-#{SecureRandom.uuid}" }
    amount -100_000
    description "My Expense"
  end
end
