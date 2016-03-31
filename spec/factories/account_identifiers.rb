FactoryGirl.define do
  factory :account_identifier do
    user { create(:user) }
    type 'credit_card'
    identifier { "#{SecureRandom.random_number(1000..9999)}-#{SecureRandom.random_number(1000..9999)}" }
    account_uid nil
    sample_transaction_party_name nil
    sample_transaction_description nil
    sample_transaction_amount nil
    sample_transaction_datetime nil
  end
end
