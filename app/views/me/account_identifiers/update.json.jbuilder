json.key_format!(camelize: :lower) if camelize_keys

json.account_identifier @account_identifier, partial: '_models/account_identifier', as: :account_identifier

if @error
  json.error @error
end
