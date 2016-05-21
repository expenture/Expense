class Me::Accounts::TransactionsController < Me::TransactionsController
  before_action :doorkeeper_authorize!

  # This controller inherits Me::TransactionsController

  private

  def resource_collection
    if params[:deleted]
      current_user.accounts.find_by!(uid: params[:account_id]).transactions.only_deleted
    else
      current_user.accounts.find_by!(uid: params[:account_id]).transactions
    end
  end

  def general_permitted_param_names
    %w(amount description category_code note datetime latitude longitude separate_transaction_uid ignore_in_statistics)
  end
end
