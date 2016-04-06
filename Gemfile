source 'https://rubygems.org'

ruby '2.3.0'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '>= 5.0.0.beta2', '< 5.1'
# Loads environment variables from `.env`
gem 'dotenv-rails', require: 'dotenv/rails-now'
# Use sqlite3 as the development database for Active Record
gem 'sqlite3', :groups => [:development, :test]
# Use postgres or mysql as the production database for Active Record
gem 'pg'
gem 'mysql2'
# Use Puma as the app server
gem 'puma'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.4'
# Redis
gem 'redis', '~> 3.0'
gem 'redis-namespace'

gem 'sinatra', github: 'sinatra/sinatra', branch: 'master', require: false

# Wrapper for the standard Ruby OpenSSL library
gem 'encryptor'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
gem 'rack-cors'

# HTTP client
gem 'rest-client'

# In-database key-value storage
gem 'rails-settings-cached', github: 'Neson/rails-settings-cached'

# Job runner and clock
gem 'sidekiq', '~> 3.4.2'
gem 'sidekiq-unique-jobs'
gem 'clockwork', '~> 1.2.0'

# User authentication
gem 'devise', '~> 4.0.0.rc1'
gem 'doorkeeper', github: 'ashishtajane/doorkeeper', branch: 'fix_issue_774'
gem 'omniauth-facebook'

# Controller helpers
gem 'api_helper', '~> 0.1.1'
gem 'kaminari'

# Geo related tools
gem 'geocoder'
gem 'timezone'

# Auto classification lib
gem 'omnicat-bayes'

# Syncer tools
gem 'nokogiri'
gem 'capybara'
gem 'poltergeist'
gem 'rmagick'
gem 'rtesseract'

# Use Pry as the Rails console
gem 'pry-rails'
gem 'pry-byebug'
gem 'awesome_print', require: false
gem 'hirb', require: false
gem 'hirb-unicode', require: false

# Model factory and tools
gem 'factory_girl_rails'
gem 'faker'

# Services
gem 'mailgunner', '~> 2.4.0'

# Logger
gem 'lograge'
gem 'syslogger'
gem 'remote_syslog_logger'
gem 'rails_stdout_logging', require: false

# Monitoring
gem 'newrelic_rpm'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'
  # RSpec
  gem 'rspec-rails'
  gem 'spring-commands-rspec'
  gem 'shoulda-matchers'
  gem 'rspec-its'
  gem 'airborne'
  gem 'database_cleaner'
  gem 'email_spec'
  gem 'simplecov', require: false
  gem 'coveralls', require: false
  gem 'codeclimate-test-reporter', require: false
  gem 'webmock', require: false
  gem 'timecop'
end

group :development do
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  # Manage Procfile-based applications
  gem 'foreman'
  # Open the sent email directly in the browser while development
  gem 'letter_opener'
  # Annotate models
  gem 'annotate'
  # Generate ERD diagram
  gem 'rails-erd'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
