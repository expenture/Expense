class Me::SynchronizersController < ApplicationAPIController
  before_action :doorkeeper_authorize!

  def index
    @synchronizers = current_user.synchronizers
  end

  def update
    if request.put?
      @synchronizer = current_user.synchronizers.find_by(uid: params[:id]) ||
                      (Synchronizer.syncer_classes[params[:synchronizer][:type]] || Synchronizer).new(user: current_user, uid: params[:id])
      @synchronizer.assign_attributes(empty_synchronizer_params.merge(synchronizer_params.to_h))
    elsif request.patch?
      @synchronizer = current_user.synchronizers.find_by!(uid: params[:id])
      @synchronizer.assign_attributes(synchronizer_params)
    end

    status = @synchronizer.persisted? ? 200 : 201

    if @synchronizer.save
      render status: status
    else
      @error = Error.new(@synchronizer.errors)
      render status: @error.status
    end
  end

  def perform_sync
    @synchronizer = current_user.synchronizers.find_by!(uid: params[:synchronizer_id])
    if @synchronizer.perform_sync
      render status: 202
    else
      @error = Error.new(status: 400, code: 'not_performable', message: 'The syncer is not in a performable status')
      render status: @error.status
    end
  end

  private

  def synchronizer_params
    params.require(:synchronizer).permit(permitted_synchronizer_param_names)
  end

  def empty_synchronizer_params
    Synchronizer.new.serializable_hash.slice(*permitted_synchronizer_param_names)
  end

  def permitted_synchronizer_param_names
    %w(name enabled schedule passcode_1 passcode_2 passcode_3 passcode_4)
  end
end
