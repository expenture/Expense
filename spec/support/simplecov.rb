require 'simplecov'
require 'coveralls'
require 'codeclimate-test-reporter'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter,
  CodeClimate::TestReporter::Formatter
])

SimpleCov.profiles.define :app do
  load_profile "test_frameworks"

  add_filter "/config/"
  add_filter "/db/"
  add_filter "/lib/clock.rb"

  if ENV['SYNCER_COVERAGE_TEST'] == 'true'
    add_group "Synchronizers", "app/synchronizers"
  else
    add_filter "/app/synchronizers/"
  end

  add_filter "/app/services/facebook_service.rb" if ENV['INTEGRATION_TEST'] != 'true'

  add_group "Controllers", "app/controllers"
  add_group "Models", "app/models"
  add_group "Objects", "app/objects"
  add_group "Services", "app/services"
  # add_group "Mailers", "app/mailers"
  # add_group "Helpers", "app/helpers"
  add_group "Jobs", %w(app/jobs app/workers)
  add_group "Libraries", "lib"

  track_files "{app,lib}/**/*.rb"
end

SimpleCov.start :app
