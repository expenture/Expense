json.key_format!(camelize: :lower) if camelize_keys

json.error @error if @error

json.account @account, partial: '_models/account', as: :account
json.source_account @source_account, partial: '_models/account', as: :account
