class SynchronizersController < ApplicationAPIController
  def index
    @synchronizers = Synchronizer.syncer_classes_as_json.values
  end
end
