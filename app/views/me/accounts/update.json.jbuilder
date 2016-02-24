json.key_format!(camelize: :lower) if camelize_keys

json.account @account, partial: '_models/account', as: :account

if @error
  json.error @error
end
