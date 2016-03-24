FactoryGirl.define do
  factory :account_identifier do
    user { create(:user) }
    type 'credit_card'
    identifier { Faker::Business.credit_card_number }
    account_uid nil
    sample_transaction_party_name nil
    sample_transaction_description nil
    sample_transaction_amount nil
    sample_transaction_datetime nil
  end
end
