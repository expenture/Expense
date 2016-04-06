# Sidekiq configuration

# Logger
case ENV['LOGGER']
when 'stdout'
  require 'rails_stdout_logging/rails'
  Sidekiq::Logging.logger = RailsStdoutLogging::Rails.heroku_stdout_logger
when 'syslog'
  # Use syslogger
  app_name = ENV['APP_NAME'] || Rails.application.class.parent_name
  Sidekiq::Logging.logger = ActiveSupport::TaggedLogging.new(Syslogger.new(app_name, Syslog::LOG_PID, Object.const_get(ENV['SYSLOG_FACILITY'] || 'Syslog::LOG_LOCAL0')))
when 'remote'
  # Send logs to a remote server
  if !ENV['REMOTE_LOGGER_HOST'].blank? && !ENV['REMOTE_LOGGER_PORT'].blank?
    app_name = ENV['APP_NAME'] || Rails.application.class.parent_name
    host_name = ENV['HOST_NAME'] || Socket.gethostname.tr(' ', '_')
    Sidekiq::Logging.logger = \
      RemoteSyslogLogger.new(ENV['REMOTE_LOGGER_HOST'], ENV['REMOTE_LOGGER_PORT'],
                             local_hostname: host_name,
                             program: ('rails-' + app_name.underscore))
  end
end

# Redis
redis_url = (ENV['REDIS_URL'].present? && ENV['REDIS_URL']) ||
            (ENV['REDISCLOUD_URL'].present? && ENV['REDISCLOUD_URL']) ||
            'redis://localhost:6379'
redis_namespace = (ENV['REDIS_NAMESPACE'] || ENV['APP_NAME'] || Rails.application.class.parent_name).underscore.tr(' ', '_')

redis_conn = lambda do
  conn = Redis.new(url: redis_url)
  Redis::Namespace.new(redis_namespace, redis: conn)
end

Sidekiq.configure_server do |config|
  config.redis = ConnectionPool.new(&redis_conn)
  config.server_middleware do |chain|
    chain.add Sidekiq::Middleware::Server::RetryJobs, max_retries: 1
  end
end

Sidekiq.configure_client do |config|
  config.redis = ConnectionPool.new(&redis_conn)
end

Sidekiq.options[:concurrency] = (ENV['WORKER_CONCURRENCY'] || 5).to_i

Sidekiq.default_worker_options = {
  unique: :until_executed,
  run_lock_expiration: 18.minutes,
  unique_args: ->(args) { args.first.except('job_id') }
}
