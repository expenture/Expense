web: bundle exec puma -C config/puma.rb
worker: bundle exec sidekiq -q default -q synchronizer_collector -q synchronizer_parser -q synchronizer_organizer
