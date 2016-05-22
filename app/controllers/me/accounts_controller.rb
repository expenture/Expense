class Me::AccountsController < ApplicationAPIController
  before_action :doorkeeper_authorize!

  def index
    @accounts = scoped_accounts
  end

  def update
    if request.put?
      @account = scoped_accounts.find_or_initialize_by(uid: params[:id])
      @account.assign_attributes(empty_account_params.merge(account_params.to_h))
    elsif request.patch?
      @account = scoped_accounts.find_by!(uid: params[:id])
      @account.assign_attributes(account_params)
    end

    status = @account.persisted? ? 200 : 201

    if @account.save
      render status: status
    else
      @error = Error.new(@account.errors)
      render status: @error.status
    end
  end

  def destroy
    @account = scoped_accounts.find_by!(uid: params[:id])

    if @account.destroy
      render
    else
      @error = Error.new(@account.errors)
      render status: @error.status
    end
  end

  def clean
    @account = scoped_accounts.find_by!(uid: params[:account_id])
    AccountOrganizingService.clean(@account)
  end

  def merge
    @account = scoped_accounts.find_by!(uid: params[:account_id])
    @source_account = scoped_accounts(with_deleted: true).find_by!(uid: params.require(:source_account_uid))
    AccountOrganizingService.merge(@source_account, @account)
    current_user.account_identifiers.where(account_uid: @source_account.uid).update_all(account_uid: @account.uid)
  end

  def transaction_categorization_suggestion
    params.require(:words)

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

  def scoped_accounts(with_deleted: false)
    if with_deleted
      current_user.accounts.with_deleted
    elsif params[:deleted]
      current_user.accounts.only_deleted
    else
      current_user.accounts
    end
  end

  def account_params
    params.require(:account).permit(permitted_account_param_names)
  end

  def empty_account_params
    Account.new.serializable_hash.slice(*permitted_account_param_names)
  end

  def permitted_account_param_names
    %w(kind name currency balance)
  end
end
