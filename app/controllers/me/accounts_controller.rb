class Me::AccountsController < ApplicationAPIController
  before_action :doorkeeper_authorize!

  def index
    @accounts = current_user.accounts
  end

  def update
    if request.put?
      @account = current_user.accounts.find_or_initialize_by(uid: params[:id])
      @account.assign_attributes(empty_account_param_set.merge(account_params.to_h))
    else request.patch?
      @account = current_user.accounts.find_by!(uid: params[:id])
      @account.assign_attributes(account_params)
    end

    status = @account.persisted? ? 200 : 201

    if @account.save
      render status: status
    else
      @error = { messages: @account.errors }
      render status: 400
    end
  end

  def destroy
    @account = current_user.accounts.find_by!(uid: params[:id])

    if @account.destroy
      render
    else
      @error = { messages: @account.errors }
      render status: 400
    end
  end

  def transaction_categorization_suggestion
    if params[:words].blank?
      @error = { message: 'Please provide the param "words".' }
      render status: 400
      return
    end

    req = Rack::Request.new(request.env)
    request_location = req.safe_location

    account = Account.find_by(uid: params[:account_id])
    user = account.user
    tcs = user.transaction_category_set

    @category_code = tcs.categorize params[:words], datetime: params[:datetime] || Time.now,
                                                    latitude: params[:latitude] || request_location.latitude,
                                                    longitude: params[:longitude] || request_location.longitude
  end

  private

  def permitted_account_param_names
    %w(type name currency balance)
  end

  def account_params
    params.require(:account).permit(permitted_account_param_names)
  end

  def empty_account_param_set
    HashWithIndifferentAccess[permitted_account_param_names.map { |v| [v, nil] }]
  end
end
