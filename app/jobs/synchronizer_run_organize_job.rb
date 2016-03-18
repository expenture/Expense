class SynchronizerRunOrganizeJob < ApplicationJob
  queue_as :synchronizer_organizer

  def perform(synchronizer:, level: :normal)
    synchronizer.run_organize(level: level.to_sym)
  end
end
