FactoryGirl.define do
  factory :virtual_transaction do
    separate_transaction { create(:transaction) }
    uid { "#{separate_transaction.uid}-#{SecureRandom.uuid}" }
    amount -100_000
    description "My Expense"
  end
end
