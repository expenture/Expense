json.key_format!(camelize: :lower) if camelize_keys

json.account_identifiers @account_identifiers, partial: '_models/account_identifier', as: :account_identifier
