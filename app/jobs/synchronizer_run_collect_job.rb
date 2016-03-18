class SynchronizerRunCollectJob < ApplicationJob
  queue_as :synchronizer_collector

  def perform(synchronizer:, level: :normal, auto_continue_syncing: false)
    synchronizer.run_collect(level: level.to_sym)

    if auto_continue_syncing
      SynchronizerRunParseJob.perform_later(synchronizer: synchronizer, level: level.to_s, auto_continue_syncing: auto_continue_syncing)
    end
  end
end
