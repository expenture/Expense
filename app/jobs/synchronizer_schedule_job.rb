class SynchronizerScheduleJob < ApplicationJob
  queue_as :synchronizer_schedule

  def perform(time)
    Synchronizer.schedule_syncers_for_time(time)
  end
end
