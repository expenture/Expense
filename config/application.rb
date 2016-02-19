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

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    config.action_mailer.delivery_method = (ENV['MAILER_DELIVERY_METHOD'].presence || :letter_opener).to_sym

    case ENV['LOGGER']
    when 'stdout'
      require 'rails_stdout_logging/rails'
      config.logger = RailsStdoutLogging::Rails.heroku_stdout_logger
    when 'remote'
      # Send logs to a remote server
      if !ENV['REMOTE_LOGGER_HOST'].blank? && !ENV['REMOTE_LOGGER_PORT'].blank?
        app_name = ENV['APP_NAME'] || Rails.application.class.parent_name
        config.logger = \
          RemoteSyslogLogger.new(ENV['REMOTE_LOGGER_HOST'], ENV['REMOTE_LOGGER_PORT'],
                                 local_hostname: "#{Socket.gethostname}".gsub(' ', '_'),
                                 program: ('rails-' + Rails.application.class.parent_name.underscore))
      end
    end
  end
end
