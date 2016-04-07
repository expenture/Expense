require 'capybara/poltergeist'

Capybara.register_driver :poltergeist do |app|
  phantomjs_path = if RUBY_PLATFORM['x86_64-darwin']
                     Rails.root.join('vendor', 'phantomjs', 'phantomjs-x86_64-darwin').to_s
                   elsif RUBY_PLATFORM['x86_64-linux']
                     Rails.root.join('vendor', 'phantomjs', 'phantomjs-x86_64-linux').to_s
                   else
                     raise "Can't load PhantomJS for OS: #{RUBY_PLATFORM}"
                   end
  options = {
    phantomjs: phantomjs_path,
    inspector: Rails.env == 'development',
    timeout: 30,
    window_size: [1920, 1080],
    js_errors: false,
    phantomjs_options: ['--ignore-ssl-errors=yes']
  }
  Capybara::Poltergeist::Driver.new(app, options)
end

Capybara.javascript_driver = :poltergeist
