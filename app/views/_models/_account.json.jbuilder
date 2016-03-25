json.uid account.uid
json.type account.type
json.name account.name
json.currency account.currency
json.balance account.balance
json.default account.default?
json.syncing account.syncing?

if time_format == 'integer'
  json.created_at account.created_at_as_i
  json.updated_at account.updated_at_as_i
else
  json.created_at account.created_at
  json.updated_at account.updated_at
end

json.errors account.errors if account.errors.present?
