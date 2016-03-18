json.account_uid transaction.account_uid
json.uid transaction.uid
json.amount transaction.amount
json.description transaction.description
json.category_code transaction.category_code
json.note transaction.note
json.datetime transaction.datetime
json.latitude transaction.latitude
json.longitude transaction.longitude
json.ignore_in_statistics transaction.ignore_in_statistics

if time_format == 'integer'
  json.created_at transaction.created_at_as_i
  json.updated_at transaction.updated_at_as_i
else
  json.created_at transaction.created_at
  json.updated_at transaction.updated_at
end

json.errors transaction.errors if transaction.errors.present?
