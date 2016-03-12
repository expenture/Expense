class Me::TransactionCategorySetController < ApplicationAPIController
  before_action :doorkeeper_authorize!

  def show
    tcs = current_user.transaction_category_set
    @transaction_category_set = tcs.hash
  end

  def update
    if request.put?
      tcs = current_user.transaction_category_set
      tcs.hash = params.require(:transaction_category_set).permit!.to_h
      @transaction_category_set = tcs.hash
    elsif request.patch?
      @error = { messages: 'PATCH request is not supported for this API endpoint. Use PUT!' }
      render status: 400
    end
  end
end
