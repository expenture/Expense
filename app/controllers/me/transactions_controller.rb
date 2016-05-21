class Me::TransactionsController < ApplicationAPIController
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

  def show
    @transaction = resource_collection.find_by!(uid: params[:id])
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
        Rails.logger.error(e)
      end
    elsif request.patch?
      @transaction = resource_collection.find_by!(uid: params[:id])
      @transaction.assign_attributes(transaction_params)
    end

    @transaction.manually_edited = true
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
    if params[:deleted]
      current_user.transactions.only_deleted
    else
      current_user.transactions
    end
  end

  def permitted_transaction_param_names
    if request.request_method_symbol == :post
      general_permitted_param_names + post_permitted_param_names
    else
      general_permitted_param_names
    end
  end

  def general_permitted_param_names
    %w(account_uid amount description category_code note datetime latitude longitude separate_transaction_uid ignore_in_statistics)
  end

  def post_permitted_param_names
    %w(uid)
  end

  def transaction_params
    params.require(:transaction).permit(permitted_transaction_param_names)
  end

  def empty_transaction_param_set
    HashWithIndifferentAccess[permitted_transaction_param_names.map { |v| [v, nil] }]
  end
end
