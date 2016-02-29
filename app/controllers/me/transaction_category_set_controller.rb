class Me::TransactionCategorySetController < ApplicationAPIController
  before_action :doorkeeper_authorize!

  def show
    tcs = TransactionCategoryService.new(current_user)
    @transaction_category_set = tcs.transaction_category_set
  end

  def update
    if request.put?
      tcs = TransactionCategoryService.new(current_user)
      tcs.transaction_category_set = HashWithIndifferentAccess.new(params.require(:transaction_category_set).permit!.to_h)
      @transaction_category_set = tcs.transaction_category_set
    elsif request.patch?
      @error = { messages: 'PATCH request is not supported for this API endpoint. Use PUT!' }
      render status: 400
    end
  end
end
