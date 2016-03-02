require File.expand_path('../../../config/environment', __FILE__)

namespace :dev do
  desc "Seed data for development environment"
  task :prime do
    # Only run this on development or staging
    if (Rails.env.development? || ENV['STAGING'].present?) && User.first.blank?
      include FactoryGirl::Syntax::Methods

      # Base user
      create :user, :confirmed

      # Base transaction categorization cases
      create :transaction_categorization_case, words: 'Sandwich', category_code: 'meal'
      create :transaction_categorization_case, words: 'Steak', category_code: 'meal'
      create :transaction_categorization_case, words: 'Pork Chop', category_code: 'meal'
      create :transaction_categorization_case, words: 'Roast Chicken', category_code: 'meal'
      create :transaction_categorization_case, words: 'Spaghetti', category_code: 'meal'
      create :transaction_categorization_case, words: 'Hamburger', category_code: 'meal'
      create :transaction_categorization_case, words: 'Baked Rice', category_code: 'meal'
      create :transaction_categorization_case, words: '三明治', category_code: 'meal'
      create :transaction_categorization_case, words: '牛排', category_code: 'meal'
      create :transaction_categorization_case, words: '豬排', category_code: 'meal'
      create :transaction_categorization_case, words: '烤雞', category_code: 'meal'
      create :transaction_categorization_case, words: '義大利麵', category_code: 'meal'
      create :transaction_categorization_case, words: '漢堡', category_code: 'meal'
      create :transaction_categorization_case, words: '焗烤飯', category_code: 'meal'
      create :transaction_categorization_case, words: 'Ice Tea', category_code: 'drinks'
      create :transaction_categorization_case, words: 'Hot Tea', category_code: 'drinks'
      create :transaction_categorization_case, words: 'Black Tea', category_code: 'drinks'
      create :transaction_categorization_case, words: 'Orange Juice', category_code: 'drinks'
      create :transaction_categorization_case, words: 'Grape Juice', category_code: 'drinks'
      create :transaction_categorization_case, words: '紅茶', category_code: 'drinks'
      create :transaction_categorization_case, words: '綠茶', category_code: 'drinks'
      create :transaction_categorization_case, words: '珍珠奶茶', category_code: 'drinks'
      create :transaction_categorization_case, words: '柳橙汁', category_code: 'drinks'
      create :transaction_categorization_case, words: '葡萄汁', category_code: 'drinks'
      create :transaction_categorization_case, words: 'SNICKERS', category_code: 'snacks'
      create :transaction_categorization_case, words: 'Pringle\'s Newfangled Potato Chips', category_code: 'snacks'
      create :transaction_categorization_case, words: 'Doritos', category_code: 'snacks'
      create :transaction_categorization_case, words: '士力架 巧克力', category_code: 'snacks'
      create :transaction_categorization_case, words: '品客 洋芋片', category_code: 'snacks'
      create :transaction_categorization_case, words: '多力多滋', category_code: 'snacks'
    end
  end
end
