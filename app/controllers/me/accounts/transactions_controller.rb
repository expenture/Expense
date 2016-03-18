class Me::Accounts::TransactionsController < ApplicationAPIController
  before_action :doorkeeper_authorize!

  def index
    # Filterable
    collection = filter(resource_collection)

    # Sortable
    sortable default_order: { datetime: :desc }

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
    req = Rack::Request.new(request.env)

    if request.put?
      @transaction = resource_collection.find_or_initialize_by(uid: params[:id])
      @transaction.assign_attributes(empty_transaction_param_set.merge(transaction_params.to_h))

      # Set the default latitude/longitude base on the request location
      begin
        if @transaction.latitude.blank? &&
           @transaction.longitude.blank?
          request_location = req.safe_location

          if request_location.latitude != 0 ||
             request_location.longitude != 0
            @transaction.latitude = request_location.latitude
            @transaction.longitude = request_location.longitude
          end
        end
      rescue Exception => e
      end
    elsif request.patch?
      @transaction = resource_collection.find_by!(uid: params[:id])
      @transaction.assign_attributes(transaction_params)
    end

    status = @transaction.persisted? ? 200 : 201

    if @transaction.save
      # Create or update the transaction categorization case
      if @transaction.category_code.present? &&
         (@transaction.description.present? || @transaction.note.present?)
        transaction_categorization_case = TransactionCategorizationCase.find_or_initialize_by(user_id: @transaction.account.user_id, transaction_uid: @transaction.uid)
        transaction_categorization_case.words = "#{@transaction.description} #{@transaction.note}"
        transaction_categorization_case.category_code = @transaction.category_code
        transaction_categorization_case.save
      end

      render status: status
    else
      @error = Error.new(@transaction.errors)
      render status: @error.status
    end
  end

  def destroy
    @transaction = resource_collection.find_by!(uid: params[:id])

    if @transaction.destroy
      render
    else
      @error = Error.new(@transaction.errors)
      render status: @error.status
    end
  end

  private

  def resource_collection
    current_user.accounts.find_by!(uid: params[:account_id]).transactions
  end

  def permitted_transaction_param_names
    %w(amount description category_code note datetime latitude longitude ignore_in_statistics)
  end

  def transaction_params
    params.require(:transaction).permit(permitted_transaction_param_names)
  end

  def empty_transaction_param_set
    HashWithIndifferentAccess[permitted_transaction_param_names.map { |v| [v, nil] }]
  end
end
