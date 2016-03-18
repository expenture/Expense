require File.expand_path('../../config/boot',        __FILE__)
require File.expand_path('../../config/environment', __FILE__)

require 'clockwork'

module Clockwork
  configure do |config|
    config[:logger] = Rails.logger
  end

  every(1.hour, 'synchronizer.schedule', at: %w(**:00 **:10 **:20 **:30 **:40 **:50)) do
    hour = '%02d' % Time.now.utc.hour
    minute = '%02d' % ((Time.now.utc.min / 10.0 + 0.5).to_i * 10)
    time = "#{hour}:#{minute}"

    SynchronizerScheduleJob.perform_later(time)
  end
end
