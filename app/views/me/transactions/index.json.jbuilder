json.key_format!(camelize: :lower) if camelize_keys

json.error @error if @error

json.transactions @transactions, partial: '_models/transaction', as: :transaction

json.pagination do
  json.items_count @items_count
  json.pages_count @pages_count

  json.links do
    json.first @first_page_url if @first_page_url
    json.prev @prev_page_url if @prev_page_url
    json.next @next_page_url if @next_page_url
    json.last @last_page_url if @last_page_url
  end
end
