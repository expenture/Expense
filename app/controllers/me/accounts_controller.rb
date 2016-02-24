class Me::AccountsController < ApplicationAPIController
  before_action :doorkeeper_authorize!

  def index
    @accounts = current_user.accounts
  end

  def update
    if request.put?
      @account = current_user.accounts.find_or_initialize_by(uid: params[:id])
      @account.replace_attributes(account_params)
    else request.patch?
      @account = current_user.accounts.find_by!(uid: params[:id])
      @account.update_attributes(account_params)
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

  private

  def account_params
    params.require(:account).permit(%w(type name currency balance))
  end
end
