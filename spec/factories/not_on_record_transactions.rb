FactoryGirl.define do
  factory :not_on_record_transaction do
    account { create(:account) }
    uid { "#{account.uid}-#{SecureRandom.uuid}" }
    amount -100_000
    description "My Expense"
  end
end
