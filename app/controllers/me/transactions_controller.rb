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

  private

  def resource_collection
    current_user.transactions
  end
end
