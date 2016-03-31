class Me::AccountIdentifiersController < ApplicationAPIController
  before_action :doorkeeper_authorize!

  def index
    @account_identifiers = current_user.account_identifiers
  end

  def update
    @account_identifier = current_user.account_identifiers.find(params[:id])

    @account_identifier.assign_attributes(account_identifier_params)

    if @account_identifier.save
      render status: status
    else
      @error = Error.new(@account_identifier.errors)
      render status: @error.status
    end
  end

  private

  def account_identifier_params
    params.require(:account_identifier).permit(:account_uid)
  end
end
