class Me::Accounts::TransactionsController < ApplicationAPIController
  before_action :doorkeeper_authorize!

  def index
    # Filterable
    collection = filter(resource_collection)

    # Sortable
    sortable default_order: { date: :desc }

    # Paginatable
    pagination collection.count, default_per_page: 25, maxium_per_page: 1000

    # Collect the records
    @transactions = collection.order(sortable_sort).page(pagination_page).per(pagination_per_page)

    # Collect metadata
    @items_count = pagination_items_count
    @pages_count = pagination_pages_count
    @first_page_url = pagination_first_page_url
    @prev_page_url = pagination_prev_page_url
    @next_page_url = pagination_next_page_url
    @last_page_url = pagination_last_page_url
  end

  def update
    if request.put?
      @transaction = resource_collection.find_or_initialize_by(uid: params[:id])
      @transaction.assign_attributes(empty_transaction_param_set.merge(transaction_params.to_h))
    else request.patch?
      @transaction = resource_collection.find_by!(uid: params[:id])
      @transaction.assign_attributes(transaction_params)
    end

    status = @transaction.persisted? ? 200 : 201

    if @transaction.save
      render status: status
    else
      @error = { messages: @transaction.errors }
      render status: 400
    end
  end

  def destroy
    @transaction = resource_collection.find_by!(uid: params[:id])

    if @transaction.destroy
      render
    else
      @error = { messages: @transaction.errors }
      render status: 400
    end
  end

  private

  def resource_collection
    current_user.accounts.find_by!(uid: params[:account_id]).transactions
  end

  def permitted_transaction_param_names
    %w(amount description category_code note date latitude longitude ignore_in_statistics)
  end

  def transaction_params
    params.require(:transaction).permit(permitted_transaction_param_names)
  end

  def empty_transaction_param_set
    HashWithIndifferentAccess[permitted_transaction_param_names.map { |v| [v, nil] }]
  end
end
