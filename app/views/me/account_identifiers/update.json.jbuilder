json.key_format!(camelize: :lower) if camelize_keys

json.error @error if @error

json.account_identifier @account_identifier, partial: '_models/account_identifier', as: :account_identifier
