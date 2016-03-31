class SynchronizerRunParseJob < ApplicationJob
  queue_as :synchronizer_parser

  def perform(synchronizer:, level: :normal, auto_continue_syncing: false)
    synchronizer.run_parse(level: level.to_sym)

    if auto_continue_syncing
      SynchronizerRunOrganizeJob.perform_later(synchronizer: synchronizer, level: level.to_s)
    end
  end
end
