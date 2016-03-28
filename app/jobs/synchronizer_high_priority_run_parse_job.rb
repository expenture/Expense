class SynchronizerHighPriorityRunParseJob < ApplicationJob
  queue_as :synchronizer_high_priority_parser

  def perform(synchronizer:, level: :normal, auto_continue_syncing: false)
    synchronizer.run_parse(level: level.to_sym)

    if auto_continue_syncing
      SynchronizerHighPriorityRunOrganizeJob.perform_later(synchronizer: synchronizer, level: level.to_s)
    end
  end
end
