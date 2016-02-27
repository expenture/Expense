json.key_format!(camelize: :lower) if camelize_keys

json.transaction @transaction, partial: '_models/transaction', as: :transaction

if @error
  json.error @error
end
