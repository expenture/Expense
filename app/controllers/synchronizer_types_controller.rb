class SynchronizerTypesController < ApplicationAPIController
  def index
    @synchronizer_types = Synchronizer.syncer_classes_as_json.values
  end
end
