FactoryGirl.define do
  factory :transaction_categorization_case do
    words { Faker::Hacker.say_something_smart }
    category_code { TransactionCategorySet.transaction_category_codes.sample }
  end

  trait :with_user do
    user { create(:user) }
  end
end
