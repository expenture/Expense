source 'https://rubygems.org'

ruby '2.3.0'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '>= 5.0.0.beta2', '< 5.1'
# Loads environment variables from `.env`
gem 'dotenv-rails', require: 'dotenv/rails-now'
# Use sqlite3 as the development database for Active Record
gem 'sqlite3', :groups => [:development, :test]
# Use postgres as the production database for Active Record
gem 'pg'
# Use Puma as the app server
gem 'puma'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
# gem 'jbuilder', '~> 2.0'
# Action Cable dependencies for the Redis adapter
gem 'redis', '~> 3.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
# gem 'rack-cors'

# Use Pry as the Rails console
gem 'rb-readline'
gem 'pry-rails'
gem 'pry-byebug'
gem 'awesome_print', :require => false
gem 'hirb', :require => false
gem 'hirb-unicode', :require => false

# Model factory and tools
gem 'factory_girl_rails'
gem 'faker'

# Logger
gem 'remote_syslog_logger'
gem 'rails_stdout_logging', :require => false

# Monitoring
gem 'newrelic_rpm'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'
  # RSpec
  gem 'rspec-rails'
  gem 'spring-commands-rspec'
  gem 'shoulda-matchers', require: false
  gem 'rspec-its', require: false
  gem 'simplecov', require: false
  gem 'coveralls', require: false
  gem 'webmock'
  gem 'timecop'
end

group :development do
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  # Open the sent email directly in the browser while development
  gem 'letter_opener'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
