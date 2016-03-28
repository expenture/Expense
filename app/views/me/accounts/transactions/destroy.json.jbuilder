json.key_format!(camelize: :lower) if camelize_keys

json.error @error if @error

json.transaction @transaction, partial: '_models/transaction', as: :transaction
