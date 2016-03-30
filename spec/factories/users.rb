FactoryGirl.define do
  factory :user do
    sequence(:email) { |n| "#{Faker::Internet.user_name}#{n}@example.com" }
    password { Faker::Internet.password }

    trait :confirmed do
      from 'skip_send_confirmation_instructions'

      after(:create) do |instance|
        instance.confirm
      end
    end
  end
end
