require File.expand_path('../boot', __FILE__)

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "action_cable/engine"
# require "sprockets/railtie"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Expense
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Load additional directories for the app
    %w(objects services synchronizers).each do |dir|
      config.paths.add File.join('app', dir), glob: File.join('**', '*.rb')
      config.autoload_paths += Dir[Rails.root.join('app', dir, '*')]
    end

    Dir[Rails.root.join("lib/core_ext/**/*.rb")].each { |f| require f }

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true
    config.session_store = :cookie_store

    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins '*'
        resource '*', headers: :any, methods: :any
      end
    end

    config.middleware.use ActionDispatch::Cookies
    config.middleware.use ActionDispatch::Flash

    config.secret_token = ENV['SECRET_KEY_BASE']
    config.active_job.queue_adapter = :sidekiq

    config.action_mailer.delivery_method = (ENV['MAILER_DELIVERY_METHOD'].presence || :letter_opener).to_sym
    config.action_mailer.default_url_options = { host: ENV['APP_URL'] }

    config.i18n.default_locale = ENV['DEFAULT_LOCALE'] || :en

    # Logger configurations
    case ENV['LOGGER']
    when 'stdout'
      require 'rails_stdout_logging/rails'
      config.logger = RailsStdoutLogging::Rails.heroku_stdout_logger
    when 'syslog'
      # Use syslogger
      app_name = ENV['APP_NAME'] || Rails.application.class.parent_name
      config.logger = ActiveSupport::TaggedLogging.new(Syslogger.new(app_name, Syslog::LOG_PID, Object.const_get(ENV['SYSLOG_FACILITY'] || 'Syslog::LOG_LOCAL0')))
      config.lograge.enabled = true
      config.lograge.formatter = Lograge::Formatters::Json.new
    when 'remote'
      # Send logs to a remote server
      if !ENV['REMOTE_LOGGER_HOST'].blank? && !ENV['REMOTE_LOGGER_PORT'].blank?
        app_name = ENV['APP_NAME'] || Rails.application.class.parent_name
        host_name = ENV['HOST_NAME'] || Socket.gethostname.tr(' ', '_')
        config.logger = \
          RemoteSyslogLogger.new(ENV['REMOTE_LOGGER_HOST'], ENV['REMOTE_LOGGER_PORT'],
                                 local_hostname: host_name,
                                 program: ('rails-' + app_name.underscore))
      end
    end
  end

  # Database specific configurations
  begin
    if ActiveRecord::Base.configurations[Rails.env]['adapter'] == 'postgresql'
      Rails.application.config.active_record.schema_format = :sql
      puts "Using PostgreSQL database"
    elsif ActiveRecord::Base.configurations[Rails.env]['adapter'] == 'mysql2'
      Rails.application.config.active_record.dump_schema_after_migration = false
      Rails.application.config.active_record.schema_format = nil
      puts "Using MySQL database"
    else
      Rails.application.config.active_record.schema_format = :ruby
    end
  rescue
  end
end

$VERBOSE = nil unless ENV['DISABLE_RUBY_WARNINGS'] == 'false'
