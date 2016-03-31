web: bundle exec puma -C config/puma.rb
worker: bundle exec sidekiq -q default,3 -q synchronizer_schedule -q synchronizer_high_priority_collector,2 -q synchronizer_high_priority_parser,2 -q synchronizer_high_priority_organizer,2 -q synchronizer_collector -q synchronizer_parser -q synchronizer_organizer
clock: bundle exec clockwork lib/clock.rb
