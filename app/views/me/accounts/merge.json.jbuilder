json.key_format!(camelize: :lower) if camelize_keys

if @error
  json.error @error
end

json.account @account, partial: '_models/account', as: :account
json.source_account @source_account, partial: '_models/account', as: :account
