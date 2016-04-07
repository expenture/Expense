require 'database_cleaner'

RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.clean_with(:deletion) if ActiveRecord::Base.configurations[Rails.env]['adapter'] == 'sqlite'
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each) do |example|
    DatabaseCleaner.start unless example.metadata[:preserve_db]
  end

  config.after(:each) do |example|
    DatabaseCleaner.clean unless example.metadata[:preserve_db]
  end

  config.after(:all) do
    DatabaseCleaner.clean_with(:deletion) if ActiveRecord::Base.configurations[Rails.env]['adapter'] == 'sqlite'
  end
end
